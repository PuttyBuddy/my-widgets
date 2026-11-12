import WidgetKit
import SwiftUI

@main
struct MyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        LauncherWidget()
        ClockWidget()
        SmallClockWidget()
        WeatherWidget()
        WaterWidget()
    }
}
