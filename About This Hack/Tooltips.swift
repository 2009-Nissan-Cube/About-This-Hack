import Foundation

let osVersiontoolTip = HCVersion.shared.getOSBuildInfo()

let systemVersiontoolTip = osVersiontoolTip

let macModeltoolTip = HCMacModel.shared.macName + " - " + HCMacModel.shared.getModelIdentifier() + "\n" + run("system_profiler SPPCIDataType | grep \":$\" | sed 's/://g'")

let cputoolTip = HCCPU.shared.getCPU() + "\n" + HCCPU.shared.getCPUInfo()

let ramtoolTip = run("cat " + InitGlobVar.sysmemFilePath)

let startupDisktoolTip = HCStartupDisk.shared.getStartupDiskInfo()

let displaytoolTip = HCDisplay.shared.getDispInfo()

let graphicstoolTip = HCGPU.shared.getGPUInfo()

let serialToggletoolTip = HCSerialNumber.shared.getHardwareInfo()

let startupDiskImagetoolTip = run("cat " + InitGlobVar.bootvollistFilePath)

let storageValuetoolTip = startupDisktoolTip

let blVersiontoolTip = "BootLoader: " + HCBootloader.shared.getBootloader() + "\nBoot-args: " + HCBootloader.shared.getBootargs()

let btSysInfotoolTip = " Hardware, Network, Software, Etc. Detailed Data"
let btSoftUpdtoolTip = " Find and Install OS and Security Updates"

