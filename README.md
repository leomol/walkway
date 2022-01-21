# Walkway - motion detector

Capture high frame rate videos of a custom-made, CatWalk like setup for mice using a FLIR's BlackFly camera.
A video is saved to disk whenever motion is detected and if locomotion satisfies the criteria defined in the configuration (e.g. ignoring brief periods of locomotion).

## Installation
* Install [SpinView (Spinnaker Web Installer)][SpinView]
* Install [Python version 3.8][Python38]
* Open `cmd`
* Run `pip install walkway` or `python -m pip install walkway`.

## Usage overview
* Power on IR light source.
* Plug in camera to computer.
* Adjust camera settings using SpinView (optional)
	- Adjust camera aperture and focus to view region of interest under the light conditions expected during the experiment.
	- Adjust image format to limit the view to the apparatus' walkway. Note that some parameters can only be changed when acquisition is off.
* Open `cmd`
* Run `python -m walkway.capture` to start auto-triggering.
* Press `q` on the GUI or `ctrl+c` on the command window when done.
* Video files are saved to cmd's working directory (defaults to `C:/Users/<your username>` in Windows). You may `cd` to a different directory prior to start capturing to save videos elsewhere.
* You may use a configuration file in JSON format with `python -m walkway.capture --configuration configuration.json`; this will override any parameters previously set to the camera.
* Run `python -m walkway.capture --help` for more information.

* Run `python -m walkway.gui` to open GUI.
* Run `python -m walkway.experiment` to open an experiment with two FLIR cameras and a Petteron microphone.


## Version History
* 0.0.9: Fixed folder select and load profile in experiment.
* 0.0.8: Added a GUI and an experiment.
* 0.0.7: Changed defaults. Added image parameters.
* 0.0.4: Add argument parser and configuration file.
* 0.0.1: Initial release. Scripts are multithreaded so as to not lag during writing operations to disk.


## License
© 2021 [Leonardo Molina][HOME]

This project is licensed under the [GNU GPLv3 License][LICENSE].

[HOME]: https://github.com/leomol
[LICENSE]: https://github.com/leomol/walkway/blob/master/LICENSE
[SpinView]: https://www.flir.ca/products/spinnaker-sdk/
[Python38]: https://www.python.org/downloads/