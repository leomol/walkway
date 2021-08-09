# Walkway - motion detector

Capture high-framerate videos of a custom-made, CatWalk-like setup for mice using FLIR's BlackFly cameras.
A video is saved to disk every time motion is detected.

## Installation
* Install [SpinView][SpinView]
* Install [Python version 3.8][Python38]
* Open `cmd`
* Run `pip install sidewalk` or `python -m pip install sidewalk`.

## Usage overview
* Power on IR ligth source.
* Plug in camera to computer.
* Setup camera using SpinView, if necessary:
	- Start acquisition.
	- Adjust camera aperture and focus to view region of interest under the light conditions expected during the experiment.
	- Adjust image format to limit the view to the apparatus' sidewalk.
	- Stop acquisition.
* Open `cmd`
* Run `python -m sidewalk`
* Press `q` on the GUI or `ctrl+c` on the command window when done.
* Video files are saved to the working directory of `cmd` (defaults to `C:/Users/<your username>` in Windows).


## Version History
* 0.0.1: Initial release. Scripts are multi-threaded so as to not lag during writing operations to disk.


## License
© 2021 [Leonardo Molina][HOME]

This project is licensed under the [GNU GPLv3 License][LICENSE].

[HOME]: https://github.com/leomol
[LICENSE]: https://github.com/leomol/sidewalk/blob/master/LICENSE
[SpinView]: https://www.flir.ca/products/spinnaker-sdk/
[Python38]: https://www.python.org/downloads/