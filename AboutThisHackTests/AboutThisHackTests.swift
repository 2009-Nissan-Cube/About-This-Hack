import XCTest
@testable import About_This_Hack

final class FormattingTests: XCTestCase {
    func testProcessorNames() {
        XCTAssertEqual(HCCPU.displayName(brand: "Apple M4 Pro", coresPerPackage: 14, packages: 1), "Apple M4 Pro (14-Core)")
        XCTAssertEqual(HCCPU.displayName(brand: "Intel(R) Core(TM) i9-9900K CPU @ 3.60GHz", coresPerPackage: 8, packages: 1),
                       "3.6 GHz 8-Core Intel Core i9-9900K")
        XCTAssertEqual(HCCPU.displayName(brand: "Intel(R) Xeon(R) CPU           X5690  @ 3.47GHz", coresPerPackage: 6, packages: 2),
                       "2 x 3.47 GHz 6-Core Intel Xeon X5690")
        XCTAssertEqual(HCCPU.displayName(brand: "AMD Ryzen 9 5950X 16-Core Processor", coresPerPackage: 16, packages: 1),
                       "AMD Ryzen 9 5950X 16-Core")
    }

    func testOpenCoreVersion() {
        XCTAssertEqual(HCBootloader.parseOpenCoreVersion("REL-100-2024-04-01"), "OpenCore 1.0.0 (Release)")
        XCTAssertEqual(HCBootloader.parseOpenCoreVersion("DEB-097-2023-12-04"), "OpenCore 0.9.7 (Debug)")
        XCTAssertNil(HCBootloader.parseOpenCoreVersion("garbage"))
    }

    func testProfilerValuesSkipEmptySlots() {
        let report = """
              BANK 0/ChannelA-DIMM0:
                  Size: Empty
                  Type: Empty
              BANK 1/ChannelA-DIMM1:
                  Size: 16 GB
                  Type: DDR4
                  Speed: 2667 MHz
        """
        XCTAssertEqual(profilerValues("Type", in: report), ["Empty", "DDR4"])
        XCTAssertEqual(profilerValues("Speed", in: report), ["2667 MHz"])
        XCTAssertEqual(profilerValues("Type", in: nil), [])
    }

    func testVersionComparison() {
        XCTAssertTrue(isVersion("3.1.0", atLeast: "3.0.0"))
        XCTAssertTrue(isVersion("v3.0", atLeast: "3.0.0"))
        XCTAssertFalse(isVersion("2.10.0", atLeast: "3.0"))
        XCTAssertEqual(compareVersionStrings("2.10", "2.9"), .orderedDescending)
    }

    func testTooltipTrimming() {
        XCTAssertEqual(trimmedTooltip("a\n\n  \nb\n"), "a\nb")
    }
}

final class LocalizationTests: XCTestCase {
    private func keys(_ language: String) throws -> Set<String> {
        let path = try XCTUnwrap(Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: language))
        let table = try XCTUnwrap(NSDictionary(contentsOfFile: path) as? [String: String])
        return Set(table.keys)
    }

    func testLanguagesShareKeys() throws {
        let english = try keys("en")
        XCTAssertFalse(english.isEmpty)
        for language in ["es", "fr"] {
            let other = try keys(language)
            XCTAssertEqual(english.subtracting(other), [], "missing in \(language)")
            XCTAssertEqual(other.subtracting(english), [], "extra in \(language)")
        }
    }
}

final class LiveHardwareTests: XCTestCase {
    func testCollectorsReturnValues() {
        XCTAssertFalse(HCCPU.shared.getCPU().isEmpty)
        XCTAssertFalse(HCGPU.shared.getGPU().isEmpty)
        XCTAssertFalse(HCMacModel.shared.macName.isEmpty)
        XCTAssertFalse(HCStartupDisk.shared.getStartupDisk().isEmpty)
        XCTAssertTrue(HCRAM.shared.getRam().hasSuffix("GB") || HCRAM.shared.getRam().contains("GB "))
    }
}
