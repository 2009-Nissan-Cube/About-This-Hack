import Foundation

/// Tooltips class with lazy computed properties to avoid expensive operations at module load time
/// All properties are computed on-demand and thread-safe
class Tooltips {
    static let shared = Tooltips()
    private init() {}

    var osVersiontoolTip: String {
        HCVersion.shared.getOSBuildInfo()
    }

    var systemVersiontoolTip: String {
        osVersiontoolTip
    }

    private lazy var _macModeltoolTip: String = {
        let pciData = run("system_profiler SPPCIDataType | grep \":$\" | sed 's/://g'")
        return HCMacModel.shared.macName + " - " + HCMacModel.shared.getModelIdentifier() + "\n" + pciData
    }()
    var macModeltoolTip: String { _macModeltoolTip }

    var cputoolTip: String {
        HCCPU.shared.getCPU() + "\n" + HCCPU.shared.getCPUInfo()
    }

    var ramtoolTip: String {
        HardwareCollector.shared.getCachedFileContent(InitGlobVar.sysmemFilePath) ?? ""
    }

    var startupDisktoolTip: String {
        HCStartupDisk.shared.getStartupDiskInfo()
    }

    var displaytoolTip: String {
        HCDisplay.shared.getDispInfo()
    }

    var graphicstoolTip: String {
        HCGPU.shared.getGPUInfo()
    }

    var serialToggletoolTip: String {
        HCSerialNumber.shared.getHardwareInfo()
    }

    var startupDiskImagetoolTip: String {
        HardwareCollector.shared.getCachedFileContent(InitGlobVar.bootvollistFilePath) ?? ""
    }

    var storageValuetoolTip: String {
        startupDisktoolTip
    }

    var blVersiontoolTip: String {
        String(format: NSLocalizedString("tooltip.bootloader", comment: "Bootloader tooltip format"), 
           HCBootloader.shared.getBootloader(), 
           HCBootloader.shared.getBootargs())
    }
    var btSysInfotoolTip: String {
        NSLocalizedString("tooltip.sysinfo", comment: "System Info button tooltip")
    }
    var btSoftUpdtoolTip: String {
        NSLocalizedString("tooltip.softupd", comment: "Software Update button tooltip")
    }
}

