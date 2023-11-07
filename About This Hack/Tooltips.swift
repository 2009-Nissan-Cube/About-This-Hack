import Foundation

let osVersiontoolTip = "\n" + HCVersion.getOSBuildInfo()

let systemVersiontoolTip = osVersiontoolTip

let macModeltoolTip = "\n" + HCMacModel.macName + " - " + HCMacModel.getModelIdentifier() + "\n\n" + run("system_profiler SPPCIDataType | grep \":$\" | sed 's/://g'")

let cputoolTip = "\n" + HCCPU.getCPU() + "\n\n" + HCCPU.getCPUInfo()

let ramtoolTip = run("cat " + initGlobVar.sysmemFilePath)

let startupDisktoolTip = HCStartupDisk.getStartupDiskInfo()

let displaytoolTip = "\n" + HCDisplay.getDispInfo()

let graphicstoolTip = "\n" + HCGPU.getGPUInfo()

let serialToggletoolTip = "\n" + HCSerialNumber.getHardWareInfo()

let startupDiskImagetoolTip = run("cat " + initGlobVar.bootvollistFilePath)

let storageValuetoolTip = startupDisktoolTip

let blVersiontoolTip = "\nBootLoader: " + HCBootloader.getBootloader() + "\nBoot-args: " + HCBootloader.getBootargs()

let btSysInfotoolTip = " Hardware, Network, Software, Etc. Detailed Data"
let btSoftUpdtoolTip = " Find and Install OS and Security Updates"

