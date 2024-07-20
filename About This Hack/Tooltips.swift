import Foundation

let osVersiontoolTip = HCVersion.getOSBuildInfo()

let systemVersiontoolTip = osVersiontoolTip

let macModeltoolTip = HCMacModel.macName + " - " + HCMacModel.getModelIdentifier() + "\n\n" + run("system_profiler SPPCIDataType | grep \":$\" | sed 's/://g'")

let cputoolTip = HCCPU.getCPU() + "\n\n" + HCCPU.getCPUInfo()

let ramtoolTip = run("cat " + initGlobVar.sysmemFilePath)

let startupDisktoolTip = HCStartupDisk.getStartupDiskInfo()

let displaytoolTip = HCDisplay.getDispInfo()

let graphicstoolTip = HCGPU.getGPUInfo()

let serialToggletoolTip = HCSerialNumber.getHardWareInfo()

let startupDiskImagetoolTip = run("cat " + initGlobVar.bootvollistFilePath)

let storageValuetoolTip = startupDisktoolTip

let blVersiontoolTip = "BootLoader: " + HCBootloader.getBootloader() + "\nBoot-args: " + HCBootloader.getBootargs()

let btSysInfotoolTip = " Hardware, Network, Software, Etc. Detailed Data"
let btSoftUpdtoolTip = " Find and Install OS and Security Updates"

