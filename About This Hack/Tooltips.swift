import Foundation

let osVersiontoolTip = "\n" + HCVersion.getOSBuildInfo()

let systemVersiontoolTip = osVersiontoolTip

let macModeltoolTip = "\n" + HCMacModel.macName + " - " + HCMacModel.getModelIdentifier() + "\n"

let cputoolTip = "\n" + HCCPU.getCPUInfo()

let ramtoolTip = run("cat " + initGlobVar.sysmemFilePath)

let startupDisktoolTip = HCStartupDisk.getStartupDiskInfo()

let displaytoolTip = "\n" + HCDisplay.getDispInfo()

let graphicstoolTip = "\n" + HCGPU.getGPUInfo()

let serialToggletoolTip = "\n" + HCSerialNumber.getHardWareInfo()

let startupDiskImagetoolTip = run("cat " + initGlobVar.bootvollistFilePath)

let storageValuetoolTip = startupDisktoolTip

let blVersiontoolTip = "\nBootLoader: " + HCBootloader.getBootloader() + "\nBoot-args: " + HCBootloader.getBootargs()

let btSysInfotoolTip = " Hardware, Network and Sofware detailed data"
let btSoftUpdtoolTip = " Find and Install OS Updates, Security Updates and App Store Applications Updates"

