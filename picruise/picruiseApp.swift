import ComposableArchitecture
import SwiftUI

@main
struct picruiseApp: App {
    var body: some Scene {
        let horizontalJoystick = JoystickState(direction: Direction.horizontal)
        let verticalJoystick = JoystickState(direction: Direction.vertical)
        
        let store = Store(
            initialState: CruiseState(
                horizontalJoystick: horizontalJoystick,
                verticalJoystick: verticalJoystick),
            reducer: cruiseReducer,
            environment: CruiseEnvironment(
                apiClient: ApiClient.live,
                mainQueue: DispatchQueue.main.eraseToAnyScheduler()
            )
        )
        
        WindowGroup {
            ContentView(store: store)
        }
    }
}
