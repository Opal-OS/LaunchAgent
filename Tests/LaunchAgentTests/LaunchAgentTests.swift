import XCTest
@testable import LaunchAgent

class LaunchAgentTests: XCTestCase {
    
    let testJobMD5 = "fcdeb223b21face810670bdd83844ef8"

    func testValidity() {
        let launchAgent = LaunchAgent(program: "/bin/echo", "LaunchAgentTests")
        let interval = StartCalendarInterval(month: 1, weekday: 1, day: 1, hour: 1, minute: 1)
        
//        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        
        launchAgent.label = "Launch Agent Test"
        
        // Program
        launchAgent.workingDirectory = "/"
        launchAgent.standardInPath = "/tmp/LaunchAgentTest.stdin"
        launchAgent.standardOutPath = "/tmp/LaunchAgentTest.stdout"
        launchAgent.standardErrorPath = "/tmp/LaunchAgentTest.stderr"
        launchAgent.environmentVariables = ["envVar": "test"]
        
        // Run Conditions
        launchAgent.runAtLoad = true
        launchAgent.startInterval = 300
        launchAgent.startCalendarInterval = interval
        launchAgent.startOnMount = true
        launchAgent.onDemand = true
        launchAgent.keepAlive = false
        launchAgent.watchPaths = ["/"]
        launchAgent.queueDirectories = ["/"]
        
        // Security
        launchAgent.umask = 18
        
        // Run Constriants
        launchAgent.launchOnlyOnce = false
        launchAgent.limitLoadToSessionType = ["Aqua", "LoginWindow"]
        launchAgent.limitLoadToHosts = ["testHost"]
        launchAgent.limitLoadFromHosts = ["testHost II"]
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        do {
            let data = try encoder.encode(launchAgent)

            guard let string = String(data: data, encoding: .utf8) else {
                XCTAssert(false, "Could not encode plist as string")
                return
            }
            
            let md5er = Process()
            let stdOutPipe = Pipe()
            
            md5er.launchPath = "/sbin/md5"
            md5er.arguments = ["-q", "-s", string]
            md5er.standardOutput = stdOutPipe
            
            md5er.launch()
            
            // Process Pipe into a String
            let stdOutputData = stdOutPipe.fileHandleForReading.readDataToEndOfFile()
            let stdOutString = String(bytes: stdOutputData, encoding: String.Encoding.utf8)?.replacingOccurrences(of: "\n", with: "")
            
            md5er.waitUntilExit()

            XCTAssertEqual(testJobMD5, stdOutString)
            
        } catch {
            XCTAssert(false)
        }
        
    }
}
