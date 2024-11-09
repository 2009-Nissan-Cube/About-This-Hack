//
//  SystemFunctions.swift
//

import Cocoa
import AppKit

var thisComponent = "SystemFunctions"

var thisApplicationName          = (Bundle.main.applicationName ?? "").replacingOccurrences(of: ".app", with: "")
var thisApplicationVersion       = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String

var thisAppNameContentsResources = "\(thisApplicationName)/Contents/Resources"

var withDataFiles: Int = 0  // 0 = NO DataFiles (Data provided by system functions), 1 = Local DataFiles extraction, 2 = Linked DataFiles (Remote DataFiles sent)

//var sp_SystemProfiler = "\(InitGlobVar.sysprofLocation)"
var sp_DataMaskJson   = "-json"
var sp_DataMaskXml    = "-xml"
var sp_DataMaskEmpty  = ""

var sp_DisplaysDataType   = "SPDisplaysDataType"
var sp_HardwareDataType   = "SPHardwareDataType"
var sp_MemoryDataType     = "SPMemoryDataType"
var sp_StorageDataType    = "SPStorageDataType"
var sp_SPSoftwareDataType = "SPSoftwareDataType"

var overViewCtrlInitStep: Int  = 0
var storViewCtrlInitStep: Int  = 0
var dispViewCtrlInitStep: Int  = 0
var prefViewCtrlInitStep: Int  = 0

var viewctrl_Mac_Model: String = "Mac model unknown"
var macUCType:          String = "Unknown"
var viewctrl_Mac_Name:  String = "Mac (UNKNOWN)"
var viewctrl_OS_Name:   String = "OS unknown"
var viewctrl_Board_Id:  String = "Unknown"

var viewctrl_SIP_Displayed: String = "SIP unknown"
var viewctrl_Cpu_Displayed: String = "CPU unknown"
var viewctrl_Ram_Displayed: String = "RAM unknown"
var viewctrl_Dsk_Displayed: String = "Disk unknown"
var viewctrl_Dsp_Displayed: String = "Display unknown"
var viewctrl_Gpu_Displayed: String = "GPU unknown"
var viewctrl_SrN_Displayed: String = "Serial Num. unknown"
var viewctrl_Bld_Displayed: String = "BootLoader unknown"
var viewctrl_Bag_Displayed: String = "BootArgs unknown"

var spDisplay_gpu_List: [disp_light_s] = []
var spDisplay_dsp_List: [String] = []
var number_Of_Displays: Int = 0
var qhasBuiltInDisplay: Bool = false

var viewctrl_Dsk_Model:    String = "Unknown"
var viewctrl_Dsk_Protocol: String = "Unknown"
var viewctrl_Dsk_Location: String = "Unknown"
var viewctrl_Dsk_VolPath:  String = "Unknown"
var viewctrl_Dsk_BSDName:  String = "Unknown"
var viewctrl_Dsk_MedType:  String = "Unknown"
var viewctrl_Dsk_SizeInt:  Int64 = 0
var viewctrl_Dsk_FreeInt:  Int64 = 0
var viewctrl_Dsk_SizeStr:  String = "Unknown"
var viewctrl_Dsk_FreeStr:  String = "Unknown"
var viewctrl_Dsk_KindStr:  String = "Unknown"

var toolTips_OSNr_Info_Displayed: String = "Unknown"
var toolTips_Modl_Info_Displayed: String = "Unknown"
var toolTips_CPU_Info_Displayed:  String = "Unknown"
var toolTips_Ram_Info_Displayed:  String = "Unknown"
var toolTips_Disk_Info_Displayed: String = "Unknown"
var toolTips_Disk_List_Displayed: String = "Unknown"
var toolTips_Disp_Info_Displayed: String = "Unknown"
var toolTips_GPU_Info_Displayed:  String = "Unknown"
var toolTips_SrN_Info_Displayed:  String = "Unknown"

//IOReg
var IOMainorMasterPortDefault:UInt32 = 0
func initPortDefault() {
	if #available(macOS 12.0, *)  {
        // IOMainorMasterPortDefault = kIOMainPortDefault      // New name as of macOS 12
	} else {
		IOMainorMasterPortDefault = kIOMasterPortDefault    // Old name up to macOS 11
	}
}

struct disp_light_s {
    var spdisp_model: String? = nil                         // sppci_model key
    var spdisp_vendor: String? = nil                        // spdisplays_vendor key
    var spdisp_vram: String? = nil                          // spdisplays_vram_shared or _spdisplays_vram key
    var spdisp_metal: String? = nil                         // spdisplays_mtlgpufamilysupport key
    var spdisp_cores: Int? = nil                            // sppci_cores key
    var spdisp_ndrvs: [disp_light_det_s] = []
    var spdisp_metal_slot: String? = nil                    // _spdisplays_metal_slot key
    var spdisp_regid: String? = nil                         // _spdisplays_regid key
    var spdisp_device_id: String? = nil                     // spdisplays_device-id key
    var spdisp_revision_id: String? = nil                   // spdisplays_revision-id key
    var spdisp_bus: String? = nil                           // sppci_bus key
    var spdisp_device_type: String? = nil                   // sppci_device_type key
    var spdisp_slot_name: String? = nil                     // sppci_slot_name key
}
struct disp_light_det_s {
    var spdisp_name: String? = nil                          // _name key
    var spdisp_type: String? = nil                          // var spdisplays_display_type
    var spdisp_resol: String? = nil                         // spdisplays_resolution key
    var spdisp_pixelres: String? = nil                      // spdisplays_pixelresolution key
    var spdisp_connect: String? = nil                       // spdisplays_connection_type key : "spdisplays_internal"
    var spdisp_colordepth: String? = nil                    // spdisplays_depth key : "CGSThirtytwoBitColor"
    var spdisp_main: String? = nil                          // spdisplays_main key : "spdisplays_yes"
    var spdisp_mirror: String? = nil                        // spdisplays_mirror key : "spdisplays_off"
    var spdisp_online: String? = nil                        // spdisplays_online key : "spdisplays_yes"
}

func getNVRAM(variable nVRAMPath: String, variable nVRAMKey: String) -> String? {
	var rootPath: io_registry_entry_t
	var masterPort = IOMainorMasterPortDefault

	 guard IOMasterPort(bootstrap_port, &masterPort) == KERN_SUCCESS else {
		 print("\(thisComponent) : NO successful Acces with mastreport \(masterPort)")
		 return nil
	 }
	 guard  !(IORegistryEntryFromPath(masterPort, nVRAMPath) == 0) else {
		 print("\(thisComponent) : NO successful Access with mastreport \(masterPort) to path \(nVRAMPath)")
		 return nil
	 }
  
	rootPath = IORegistryEntryFromPath(masterPort, nVRAMPath)
	 
	let vref = IORegistryEntryCreateCFProperty(rootPath, nVRAMKey as CFString, kCFAllocatorDefault, 0)
	if (vref != nil) {
		let data = vref?.takeRetainedValue() as! Data
		var cleanedData = Data()
		for i in 0..<data.count {
			if data[i] != 0x00 {
				cleanedData.append(data[i])
			}
		}
		IOObjectRelease(rootPath)
		print("\(thisComponent) : Process \(rootPath) is released")
		return String(bytes: cleanedData, encoding: .utf8)
	} else {
		IOObjectRelease(rootPath)
		print("\(thisComponent) : Process \(rootPath) is released but WITHOUT successful access to \( nVRAMPath) with \(nVRAMKey)")
	}
	return nil
}

func ioRegFullPathContent(path ioRegPath: String, key ioRegKey: String, encode ioEncode: String) -> String {
    var rootPath: io_registry_entry_t
    var masterPort = IOMainorMasterPortDefault

    guard IOMasterPort(bootstrap_port, &masterPort) == KERN_SUCCESS else {
        print("\(thisComponent) : NO successful Acces with mastreport \(masterPort)")
        return ""
    }
    guard  !(IORegistryEntryFromPath(masterPort, ioRegPath) == 0) else {
        print("\(thisComponent) : NO successful Access with mastreport \(masterPort) to path \(ioRegPath)")
        return ""
    }

    rootPath = IORegistryEntryFromPath(masterPort, ioRegPath)
    
    var ioRegValue : String = ""
    let keyValueFound = IORegistryEntryCreateCFProperty(rootPath, ioRegKey as CFString, kCFAllocatorDefault, 0)
    if (keyValueFound != nil) {
        let notCleanedData = keyValueFound?.takeRetainedValue() as? Data
        var cleanedData = Data()
        for i in 0..<notCleanedData!.count {
            if notCleanedData![i] != 0x00 {
                cleanedData.append(notCleanedData![i])
            }
        }
        if ioEncode.lowercased().starts(with: "y") {
            ioRegValue = String(bytes: cleanedData, encoding: .utf8) ?? ""
        } else {
            ioRegValue = cleanedData.hexadecimalString()
        }
    }
    
    IOObjectRelease(rootPath)
    print("\(thisComponent) : Process \(rootPath) released for access to \(ioRegPath) with \(ioRegKey)")
    return ioRegValue
}

func getCleanedIORegValueAsString(path ioRegPath: String, key ioRegKey: String, encode ioEncode: String) -> String {
	var rootPath: io_registry_entry_t
	var masterPort = IOMainorMasterPortDefault

	guard IOMasterPort(bootstrap_port, &masterPort) == KERN_SUCCESS else {
		print("\(thisComponent) : NO successful Acces with mastreport \(masterPort)")
		return ""
	}
	guard  !(IORegistryEntryFromPath(masterPort, ioRegPath) == 0) else {
		print("\(thisComponent) : NO successful Access with mastreport \(masterPort) to path \(ioRegPath)")
		return ""
	}

	rootPath = IORegistryEntryFromPath(masterPort, ioRegPath)
	
	var ioRegValue : String = ""
	let keyValueFound = IORegistryEntryCreateCFProperty(rootPath, ioRegKey as CFString, kCFAllocatorDefault, 0)
//    print("\(thisComponent) : keyValueFound : \(String(describing: keyValueFound))")
	if (keyValueFound != nil) {
		let notCleanedData = keyValueFound?.takeRetainedValue() as? Data
		var cleanedData = Data()
		for i in 0..<notCleanedData!.count {
			if notCleanedData![i] != 0x00 {
				cleanedData.append(notCleanedData![i])
			}
		}
		if ioEncode.lowercased().starts(with: "y") {
			ioRegValue = String(bytes: cleanedData, encoding: .utf8) ?? ""
		} else {
			ioRegValue = cleanedData.hexadecimalString()
		}
	}
//    print("\(thisComponent) : ioRegValue : \(ioRegValue)")
	IOObjectRelease(rootPath)
	print("\(thisComponent) : Process \(rootPath) released for access to \(ioRegPath) with \(ioRegKey)")
	return ioRegValue
}

func getNOTCleanedIORegValueAsString(path ioRegPath: String, key ioRegKey: String, replace hexVal:UInt8, encode ioEncode: String, release freeProcess: String) -> String {
    print("\(thisComponent) : Parameters :  \(ioRegPath) \(ioRegKey) \(hexVal) \(ioEncode) \(freeProcess)")
    var rootPath: io_registry_entry_t
    var masterPort = IOMainorMasterPortDefault

    guard IOMasterPort(bootstrap_port, &masterPort) == KERN_SUCCESS else {
        print("\(thisComponent) : NO successful Acces with mastreport \(masterPort)")
        return ""
    }
    guard  !(IORegistryEntryFromPath(masterPort, ioRegPath) == 0) else {
        print("\(thisComponent) : NO successful Access with mastreport \(masterPort) to path \(ioRegPath)")
        return ""
    }

    rootPath = IORegistryEntryFromPath(masterPort, ioRegPath)
    
    var ioRegValue : String = ""
    let keyValueFound = IORegistryEntryCreateCFProperty(rootPath, ioRegKey as CFString, kCFAllocatorDefault, 0)
    if (keyValueFound != nil) {
        let notCleanedData = keyValueFound?.takeRetainedValue() as? Data
        var cleanedData = Data()
//        let hexVal = Data(bytes:newValue)
       for i in 0..<notCleanedData!.count {
            if notCleanedData![i] == 0x00 {
                cleanedData.append(hexVal) // 0x0a = "\n" or 0x2c = ","
            } else {
                cleanedData.append(notCleanedData![i])
            }
        }
        if ioEncode.lowercased().starts(with: "y") {
            ioRegValue = String(bytes: cleanedData, encoding: .utf8) ?? ""
        } else {
            ioRegValue = cleanedData.hexadecimalString()
        }
    }
    if freeProcess.lowercased().starts(with: "y") {
        IOObjectRelease(rootPath)
        print("\(thisComponent) : Process \(rootPath) released for access to \(ioRegPath) with \(ioRegKey)")
    }
    return ioRegValue
}

func getSysctlValueByKey(inputKey sysctlKey: String) -> String? {
	var oNbrBytes: Int = 0
	sysctlbyname(sysctlKey, nil, &oNbrBytes, nil, 0)
	var sysctlValue = [CChar](repeating: 0, count: Int(oNbrBytes))
	sysctlbyname(sysctlKey, &sysctlValue, &oNbrBytes, nil, 0)
	print("\(thisComponent) : " + sysctlKey + " : \(String(validatingUTF8: sysctlValue) ?? "unknown")")
	return String(validatingUTF8: sysctlValue) ?? "unknown"
}


func process(path: String, arguments: [String]) -> String? {
	let task = Process()
	task.launchPath = path
	task.arguments = arguments
	
	let outputPipe = Pipe()
	defer {
		outputPipe.fileHandleForReading.closeFile()
	}
	task.standardOutput = outputPipe
	
	do {
        if #available(macOS 10.13, *) {
            try task.run()
        } else {
            let outputData = run("\(path) \(arguments)")
            print("\(thisComponent) : macOS \(viewctrl_OS_Name) : \(outputData)")
        }
	} catch {
		print("\(thisComponent) : Error(s) with \(path) \(arguments)")
		return nil
	}
    
	let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
	let output = String(decoding: outputData, as: UTF8.self)
	
	if output.isEmpty {
		return nil
	}
	return output
}

extension Bundle {
    /// Application name shown under the application icon.
    var applicationName: String? {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
            object(forInfoDictionaryKey: "CFBundleName") as? String ??
                object(forInfoDictionaryKey: "CFBundleExecutable") as? String
    }
}

func doesDirectoryOrFileExist(absolutePath: String) -> Int {
    var testIfDirectory: ObjCBool = false // default
    var indResult      : Int      = 0     // 0 = Directory, 1 = File, -1 = absolutePath isn't a Directory nor a File (doesn't exist)
    if InitGlobVar.defaultfileManager.fileExists(atPath: absolutePath, isDirectory:&testIfDirectory) {
        if testIfDirectory.boolValue { indResult = 0
        } else { indResult = 1 }
    } else { indResult = -1 }
    return indResult
}

func doesURLFileExist(absolutePath: URL) -> Bool {
    do {
        if try absolutePath.checkResourceIsReachable() {
            print(thisComponent + ": URL file \(absolutePath) reachable")
            return true
        } else {
            print(thisComponent + ": URL file \(absolutePath) NOT reachable")
        }
    } catch {
        print(thisComponent + ": URL file error: \(error)")
    }
    return false
}

func getURLFileContentAsync(UrlFile: String) -> String {
    print(thisComponent + " : getURLFileContentAsync for \(UrlFile)")
    var urlFileContent = ""
    DispatchQueue.global().async {
        do {
            urlFileContent = try String(contentsOf: URL(string: UrlFile)!)
        }
        catch {
            urlFileContent = "\(UrlFile) : \(error)" //error as String
        }
    }
    print(thisComponent + " : " + urlFileContent)
    return urlFileContent
}
