import Foundation

/// Tooltips class with lazy computed properties to avoid expensive operations at module load time
/// All properties are computed on-demand and thread-safe
class Tooltips {
    static let shared = Tooltips()
    private init() {}

    var osVersiontoolTip: String {
        HCVersion.shared.getOSBuildInfo()
    }

    var macModeltoolTip: String {
        HCMacModel.shared.macName + " - " + HCMacModel.shared.getModelIdentifier() + "\n" + HCGPU.shared.getGPUInfo()
    }

    var cputoolTip: String {
        HCCPU.shared.getCPU() + "\n" + HCCPU.shared.getCPUInfo()
    }

    var ramtoolTip: String {
        HardwareCollector.shared.memoryData ?? ""
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
        HCStartupDisk.shared.getStartupDiskInfo()
    }

    var btSysInfotoolTip: String {
        NSLocalizedString("tooltip.sysinfo", comment: "System Info button tooltip")
    }
    var btSoftUpdtoolTip: String {
        NSLocalizedString("tooltip.softupd", comment: "Software Update button tooltip")
    }
}
