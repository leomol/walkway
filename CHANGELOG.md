## Data analysis changelog
* 2023-09-15
	- Added `interlimbCoordinationStats.m` to facilitate printing interlimb coordination statistics.
* 2023-08-22
	- Added a function for Watson-Williams statistics.
	- Minor documentation changes.
* 2023-08-19
	- Merged projects for data acquisition, data analysis, and manufacturing.
	- Added CAD files for manufacturing.
	- Added validation data.
	- Added interlimb coordination analysis.
	- Added example for processing generic data.
	- Added a function for Rayleigh statistics.
	- Isolated scripts specific to paper.
	- Packaged epochs, circular statistics, and lookup tables.
	- Major updates to function signatures to improve usage and readability.
* 2023-05-09
	- Added path, inferenceDate, and recordingDate to bout data.
	- Updated main to include handpicked files and to export all data into tables.
	- Simplified loadDLC, main, and setup.
* 2023-04-03
	- Initial release.

## Acquisition software changelog
* 0.0.9: Fixed folder select and load profile in experiment.
* 0.0.8: Added a GUI and an experiment.
* 0.0.7: Changed defaults. Added image parameters.
* 0.0.4: Add argument parser and configuration file.
* 0.0.1: Initial release. Scripts are multithreaded so as to not lag during writing operations to disk.