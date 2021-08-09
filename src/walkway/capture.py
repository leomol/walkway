# 2021-07-31. Leonardo Molina.
# 2021-08-09. Last modified.

from .flexible import Flexible
from .scheduler import Scheduler
from threading import Lock

import cv2
import datetime
import math
import numpy as np
import PySpin
import signal
import sys
import threading
import time
    
def getFlir(nodeMap, nodeName, getter=PySpin.CIntegerPtr):
    success = False
    exception = ""
    try:
        node = getter(nodeMap.GetNode(nodeName))
        if PySpin.IsAvailable(node):
            success = True
    except PySpin.SpinnakerException as ex:
        exception = str(ex)
        success = False
    if success:
        return node.GetValue()
    else:
        print("Error: Unable to get '%s'" % nodeName)
        if len(exception) > 0:
            print("  >>%s" % exception)
        return None
    

def setFlir(nodeMap, nodeName, value):
    success = False
    exception = ""
    
    if isinstance(value, str):
        getter = PySpin.CEnumerationPtr
        setter = lambda node, value : node.SetIntValue(node.GetEntryByName(value).GetValue())
    elif isinstance(value, bool):
        getter = PySpin.CBooleanPtr
        setter = lambda node, value : node.SetValue(value)
    elif isinstance(value, float):
        getter = PySpin.CFloatPtr
        setter = lambda node, value : node.SetValue(value)
    else:
        getter = PySpin.CIntegerPtr
        setter = lambda node, value : node.SetIntValue(value)
    
    try:
        node = getter(nodeMap.GetNode(nodeName))
        if PySpin.IsAvailable(node) and PySpin.IsWritable(node):
            setter(node, value)
            success = True
    except PySpin.SpinnakerException as ex:
        exception = str(ex)
        success = False
    if success:
        return True
    else:
        print("Error: Unable to set '%s' to '%s'" % (nodeName, str(value)))
        if len(exception) > 0:
            print("  >>%s" % ex)
        return False

class Codec:
    Raw = 0
    MJPG = 1
    H264 = 2

class States:
    Started = 1
    Ended = 2

class Capture(object):
    @property
    def resolution(self):
        p = self.__private
        return p.resolution
    
    
    def __onKeyPress(self, event):
        p = self.__private
        key = event.key
        if key == 'q':
            p.running = False
            #sys.exit(0)
    
    
    def __onClose(self, event):
        p = self.__private
        p.running = False
        
        
    def __save(self, buffer, nFrames):
        p = self.__private
        filename = "CW-%s" % datetime.datetime.now().strftime("%Y%m%d%H%M%S%f")
        frameRate = p.frameRate
        if p.codec == Codec.Raw:
            option = PySpin.AVIOption()
            option.frameRate = frameRate
        elif p.codec == Codec.MJPG:
            option = PySpin.MJPGOption()
            option.frameRate = frameRate
            option.quality = 95
        elif p.codec == Codec.H264:
            option = PySpin.H264Option()
            option.frameRate = frameRate
            option.bitrate = 1000000
            option.height = self.resolution[1]
            option.width = self.resolution[0]
        
        recorder = PySpin.SpinVideo()
        recorder.Open(filename, option)

        b = len(buffer)
        a = max(0, b - nFrames)
        for i in range(a, b):
            recorder.Append(buffer[i])
        recorder.Close()
    
    
    def __resetBackground(self):
        p = self.__private
        p.background = cv2.createBackgroundSubtractorMOG2(history=math.ceil(p.processFrequency / p.speedThreshold), detectShadows=False)
    
    
    def __dispose(self):
        p = self.__private
        
        p.processScheduler.stop()
        p.processScheduler.join()
        p.camera.EndAcquisition()
        p.camera.DeInit()
        del p.camera
        p.flirSystem.ReleaseInstance()
    
    
    def __capture(self):
        p = self.__private
        k = 0
        while p.running:
            try:
                flirImage = p.camera.GetNextImage(int(p.grabTimeout * 1000))
                if not flirImage.IsIncomplete():
                    if k % (p.frameRate // p.processFrequency) == 0:
                        with p.processLock:
                            p.processImage = flirImage.GetNDArray().copy()
                    with p.bufferLock:
                        p.buffer.append(flirImage.Convert(PySpin.PixelFormat_Mono8, PySpin.HQ_LINEAR))
                    flirImage.Release()
            except PySpin.SpinnakerException as ex:
                print("Error: %s" % ex)
            # Free-up space every so often.
            if k % (p.frameRate // p.bufferClipFrequency) == 0:
                with p.bufferLock:
                    n = len(p.buffer) - math.ceil(p.bufferSize * p.frameRate)
                    if n > 0:
                        del p.buffer[:n]
                        print('Cleared buffer')
    
    
    def __onProcess(self):
        p = self.__private
        # Test for motion.
        ksize = (round(p.blurSize[1] * self.resolution[1]), round(p.blurSize[0] * self.resolution[0]))
        ksize = (ksize[0] + 1 if ksize[0] % 2 == 0 else ksize[0], ksize[1] + 1 if ksize[1] % 2 == 0 else ksize[1])
        with p.processLock:
            blurred = cv2.blur(src=p.processImage, ksize=ksize)
        change = p.background.apply(blurred).astype(bool) #shape = 1024x1280
        
        # Collapse height. A change for each x-pixel is reported when a proportion of y-pixels also change.
        line = change.sum(axis=0) > p.areaProportion * self.resolution[1]
        if p.lines.shape[0] < math.ceil(1 / 2 * p.processFrequency / p.speedThreshold):
            p.lines = np.vstack((p.lines, line))
        else:
            p.lines[:-1] = p.lines[1:]
            p.lines[-1] = line
            p.trail = p.lines.any(axis=0)
            
            motionScore = p.trail.sum()
            motionDuration = time.time() - p.motionStart
            save = False
            if p.motionState == States.Ended and motionScore > p.locomotionThreshold * p.resolution[0]:
                # Acceleration: high-count-lines are pushed while low-count-lines are popped.
                print("Motion started... ", end='')
                p.motionState = States.Started
                p.motionStart = time.time()
            elif p.motionState == States.Started and motionScore < p.quiescenceThreshold * p.resolution[0]:
                    # Deceleration: low-count-lines are pushed while high-count-lines are popped.
                    if motionDuration > p.minDuration:
                        # Movement lasted enough.
                        self.__setMessage("Motion detected! duration:%.2fs" % motionDuration)
                        print("accepted! duration:%.2fs" % motionDuration)
                        save = True
                    else:
                        print("ignored! Too short. duration:%.2fs" % motionDuration)
                    p.motionState = States.Ended
            elif p.motionState == States.Started and motionDuration > p.maxDuration:
                    # Movement has lasted long enough; force save.
                    self.__setMessage("Motion detected! duration:%.2fs" % motionDuration)
                    print("accepted! Splitted. duration:%.2fs" % motionDuration)
                    p.motionState = States.Ended
                    save = True
            # Save on background.
            if save:
                nFrames = math.ceil((time.time() - p.motionStart) * p.frameRate)
                with p.bufferLock:
                    buffer = p.buffer.copy()
                threading.Thread(target=self.__save, args=(buffer, nFrames)).start()
    
    def start(self):
        p = self.__private
        
        p.flirSystem = PySpin.System.GetInstance()
        cameraList = p.flirSystem.GetCameras()
        
        if cameraList.GetSize() == 0:
            cameraList.Clear()
            p.flirSystem.ReleaseInstance()
            print("Error: Camera not connected. Aborting...")
            return False
            
        p.camera = cameraList[0]
        cameraList.Clear()
        try:
            p.camera.Init()
            nodemap = p.camera.GetNodeMap()
            sNodemap = p.camera.GetTLStreamNodeMap()
        except PySpin.SpinnakerException as ex:
            print("Error: %s" % ex)
            return False
        
        success = True
        success |= setFlir(sNodemap, "StreamBufferHandlingMode", "NewestOnly")
        success |= setFlir(nodemap, "AcquisitionMode", "Continuous")
        success |= setFlir(nodemap, "ExposureAuto", "Off")
        success |= setFlir(nodemap, "GainAuto", "Off")
        success |= setFlir(nodemap, "Gamma", 0.25)
        # success |= setFlir(nodemap, "AcquisitionFrameRateEnable", True)
        # success |= setFlir(nodemap, "AcquisitionFrameRate", 120.0)
        if not success:
            return False
        
        p.frameRate = getFlir(nodemap, "AcquisitionFrameRate", getter = PySpin.CFloatPtr)
        if p.frameRate is None:
            return False
        
        try:
            p.camera.BeginAcquisition()
        except PySpin.SpinnakerException as ex:
            print("Error: %s" % ex)
            return False
        
        print("Frame rate: %.2f" % p.frameRate)
        p.resolution = (getFlir(nodemap, "Width"), getFlir(nodemap, "Height"))
        
        # Collapse height.
        p.lines = np.empty((0, self.resolution[0]))
        p.trail = np.full(self.resolution[0], False)
        p.processImage = np.zeros((self.resolution[1], self.resolution[0]), np.uint8)
        
        # Start capturing.
        p.thread = threading.Thread(target=self.__capture, args=())
        p.thread.start()
        
        # Start processing.
        p.processScheduler.repeat(interval=1.0 / p.processFrequency)
        
        while p.running:
            with p.processLock:
                frame = p.processImage.copy()
            margin = int(self.resolution[1] * p.margin)
            frame[0:margin, p.trail] = 0
            frame[-margin:-1, p.trail] = 0
            if time.time() < p.messageToc:
                self.__showMessage(frame, *p.message[0], **p.message[1])
            cv2.imshow("image", frame)
            key = cv2.waitKey(1000 // p.processFrequency) & 0xFF
            if key == ord('q'):
                p.running = False
        p.thread.join()
        self.__dispose()
        return True
    
    
    def __setMessage(self, *args, duration=1, **kwargs):
        p = self.__private
        p.messageToc = time.time() + duration
        p.message[0] = args
        p.message[1] = kwargs
        
    def __showMessage(self, image, text, center=(10, 30), color=50, fontScale=1):
        cv2.putText(
            img=image,
            text=text,
            org=center,
            fontFace=cv2.FONT_HERSHEY_SIMPLEX,
            fontScale=fontScale,
            color=color,
            thickness=3
        )
        cv2.putText(
            img=image,
            text=text,
            org=center,
            fontFace=cv2.FONT_HERSHEY_SIMPLEX,
            fontScale=fontScale,
            color=255,
            thickness=1
        )
    
    def __onKillSignal(self):
        p = self.__private
        p.running = False
        
    def __init__(self):
        p = self.__private = Flexible()
        
        # Locomotion starts when the number of active x-pixels is larger than k * width.
        p.locomotionThreshold = 0.05
        # Locomotion stops when the number of active x-pixels is smaller than k * width.
        p.quiescenceThreshold = 0.01
        # Videos are not saved if they last less than k seconds.
        p.minDuration = 0.10
        # Videos are split if they last longer than k seconds.
        p.maxDuration = 3.00
        # Speed threshold to detect motion (length-proportion/s).
        p.speedThreshold = 2.0
        # Proportion of y-pixels required to activate an x-pixel.
        p.areaProportion = 0.25
        
        p.codec = Codec.MJPG
        
        p.renderFrequency = 30
        p.processFrequency = 30
        p.bufferClipFrequency = 1
        
        p.margin = 0.05
        p.bufferSize = 10
        p.blurSize = (0.10, 0.10)
        p.grabTimeout = 1.0
        
        # State variables.
        p.running = True
        p.motionStart = time.time()
        p.motionState = States.Ended
        p.messageToc = 0
        p.message = [[], {}]
        p.bufferLock = Lock()
        p.processLock = Lock()
        p.buffer = list()
        
        p.processScheduler = Scheduler()
        p.processScheduler.subscribe(lambda scheduler: self.__onProcess())
        self.__resetBackground()
        
        signal.signal(signal.SIGINT, lambda sig, frame: self.__onKillSignal())
        signal.signal(signal.SIGTERM, lambda sig, frame: self.__onKillSignal())

if __name__ == "__main__":
    result = Capture().start()
    sys.exit(int(result))
    