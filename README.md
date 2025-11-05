# Build Script for Hydra

<img src="assets/hydra.png" width="200" align="right" />

This script will compile the [Hydra](https://github.com/SamoZ256/hydra) emulator locally on macOS.<br>
It also has these features: 
- Can automatically install/update Homebrew dependencies (or skip the checks entirely)
- Can build Debug or Release builds
- Can build SDL or SwiftUI frontends
- Can check out a specified commit or Pull Request
- Pauses so the source code can be edited before completing the build

## Running the script

When downloaded, you probably won't be able to run the script at first.<br>

- If you get a message saying that the script can't be opened, right-click on it and select `Open` from the context menu. You should now get a new option to `Open` anyway. If you are running macOS 15 Sequoia or later you may need to approve it from the `Privacy & Security` tab in the Settings app.<br>

- The default application that is used to open the script might be set to a text editor. Change the default application by selecting the script and using `Command+I` to open the `Get Info` window (or right-click and select from the context menu). Under the `Open With:` section, if Terminal is not selected choose `Other`, enable `All Applications` and navigate to `/Applications/Utilities/Terminal`. It should now open by double-clicking it.<br>

- The script was written for the `Zsh` shell environment. If run from the command line, use `zsh build_hydra.sh`. The menus will not work properly using the `Bash` command `sh build_hydra.sh`.

- If you have done the above steps and nothing happens when you run it, you may need to give it executable permissions. In Terminal, use the `cd` command to navigate to where the script is and enter `chmod +x build_hydra.sh`. <br>

Note that the script will perform all actions in the same folder you run it from (likely your `Downloads` folder), so you may need to give it permission for this, or move it somewhere else.
