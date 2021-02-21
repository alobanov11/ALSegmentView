import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ALSegmentViewTests.allTests),
    ]
}
#endif
