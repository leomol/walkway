## Data analysis changelog
* 2024-04-24
	- Simplified `rayleigh.m` to accept only angles as inputs to the function, rather than Cartesian coordinates corresponding to the angles.
* 2023-10-11
	- Fixed bug in speed calculation in `process.m`
* 2023-09-15
	- Added `interlimbCoordinationStats.m` to facilitate printing interlimb coordination statistics.
	- Edited `loadDLC.m` so that it can load DLC files with or without the filename column.
	- Added an example setup in `process.m` so that generic data can be run.
	- Updated `circular.rayleigh.m`, and `circular.watsonWilliams.m` to handle missing data.
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