import ComposableArchitecture
import SwiftUI

let host = "http://raspberrypi.local"

// MARK: - Domain
struct CruiseState: Equatable {
    static func == (lhs: CruiseState, rhs: CruiseState) -> Bool {
        return lhs.horizontalJoystick == rhs.horizontalJoystick && lhs.verticalJoystick == rhs.verticalJoystick
    }
    
    var horizontalJoystick: JoystickState
    var verticalJoystick: JoystickState
    
    var isConnected: Bool = false
    var connectionRequestInFlight: Bool = false
}

enum CruiseAction: Equatable {
    static func == (lhs: CruiseAction, rhs: CruiseAction) -> Bool {
        return true
    }
    
    case connect(Void)
    case connectResponse(Result<Void, ApiClient.Failure>)
    
    case navigateHorizontal(CGFloat)
    case navigateHorizontalResponse(Result<Void, ApiClient.Failure>)
    
    case navigateVertical(CGFloat)
    case navigateVerticalResponse(Result<Void, ApiClient.Failure>)
}

struct CruiseEnvironment {
    var apiClient: ApiClient
    var mainQueue: AnySchedulerOf<DispatchQueue>
}

// MARK: - Reducer
let cruiseReducer = Reducer<CruiseState, CruiseAction, CruiseEnvironment> {
    state, action, environment in
    switch action {
    
    case let .connect(Void):
        state.connectionRequestInFlight = true
        
        return environment.apiClient
            .connect()
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(CruiseAction.connectResponse)
    
    case let .connectResponse(.success(response)):
        state.connectionRequestInFlight = false
        return .none
    
    case .connectResponse(.failure):
        state.connectionRequestInFlight = false
        return .none
        
    case let .navigateHorizontal(distance):
        state.horizontalJoystick.navigationRequestInFlight = true
        
        //TODO: Implement endpoint to pass normalized value between -1, 1

        return environment.apiClient
            .left()
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(CruiseAction.navigateHorizontalResponse)
    
    case let .navigateHorizontalResponse(.success(response)):
        state.horizontalJoystick.navigationRequestInFlight = false
        return .none
      
    case .navigateHorizontalResponse(.failure):
        state.horizontalJoystick.navigationRequestInFlight = false
        //TODO: Implement UI element indicating that the server connection broke
        return .none

    case let .navigateVertical(distance):
        state.verticalJoystick.navigationRequestInFlight = true
            
        //TODO: Implement endpoint to pass normalized value between -1, 1
    
        return environment.apiClient
            .right()
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(CruiseAction.navigateVerticalResponse)
    
    case let .navigateVerticalResponse(.success(response)):
        state.verticalJoystick.navigationRequestInFlight = false
        return .none

    case .navigateVerticalResponse(.failure):
        state.verticalJoystick.navigationRequestInFlight = false
        //TODO: Implement UI element indicating that the server connection broke
        return .none
    }
}

//MARK: - UI Joystick
enum Direction {
    case vertical
    case horizontal
}

struct JoystickState : Equatable{
    let direction: Direction
    var draggedOffset: CGFloat = .zero
    var navigationRequestInFlight: Bool = false
}

struct DraggableModifier : ViewModifier {
    let viewStore: ViewStore<CruiseState, CruiseAction>
    let direction: Direction //TODO: Can this be replaced by viewStore?
    let maxDistance: CGFloat
    
    @State var draggedOffset: CGSize = .zero //TODO: Can this be replaced by viewStore?

    func body(content: Content) -> some View {
        content
        .offset(
            CGSize(width: direction == .vertical ?
                    0 : max(-maxDistance, min(maxDistance, draggedOffset.width)),
                   
                   height: direction == .horizontal ?
                    0 : max(-maxDistance, min(maxDistance, draggedOffset.height))
            )
        )
        .gesture(
            DragGesture()
            .onChanged { value in
                self.draggedOffset = value.translation
                
                var distance : CGFloat = 0
                if direction == Direction.horizontal {
                    distance = draggedOffset.width
                    viewStore.send(CruiseAction.navigateHorizontal(distance))
                } else {
                    distance = draggedOffset.height
                    viewStore.send(CruiseAction.navigateVertical(distance))
                }
                
            }
            .onEnded { value in
                self.draggedOffset = .zero
                
                if direction == Direction.horizontal {
                    viewStore.send(CruiseAction.navigateHorizontal(.zero))
                } else {
                    viewStore.send(CruiseAction.navigateVertical(.zero))
                }
            }
        )
    }
}

// MARK: - UI
struct ContentView: View {
    let store: Store<CruiseState, CruiseAction>
    
    let joystickRectangleLong: CGFloat = 200
    let joystickRectangleShort: CGFloat = 50
    let joystickPadding: CGFloat = 10
    
    var joystickDiameter: CGFloat
    var joystickMaxDragDistance: CGFloat
    
    var videoStream = host + ":8080/stream/video.mjpeg"

    init(store: Store<CruiseState, CruiseAction>) {
        self.store = store
        
        joystickDiameter = joystickRectangleShort - joystickPadding
        joystickMaxDragDistance = (joystickRectangleLong-joystickDiameter-joystickPadding)/2
    }
    
    var body: some View {
        WithViewStore(self.store) { viewStore in
            ZStack {
                MjpegWebView(url: videoStream)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                VStack(alignment: .center) {
                    HStack(alignment: .center) {
                        Button(viewStore.isConnected ? "Disconnect" : "Connect") { /*viewStore.send(.connect(nil))*/ }
                            .disabled(viewStore.connectionRequestInFlight)
                            .padding()
                        Text(viewStore.isConnected ? "Connected" : (viewStore.connectionRequestInFlight ? "Connecting..." : "Disconnected"))
                            .foregroundColor(viewStore.isConnected ? .green : (viewStore.connectionRequestInFlight ? .blue : .red))
                            .padding()
                    }
                    HStack(alignment: .center) {
                        ZStack(alignment: .center) {
                            RoundedRectangle(cornerRadius: joystickRectangleShort / 2, style: .continuous)
                                .fill(Color.black)
                                .frame(width: joystickRectangleLong, height: joystickRectangleShort)
                            Circle()
                                .fill(Color.blue)
                                .frame(width: joystickDiameter, height: joystickDiameter)
                                .modifier(DraggableModifier(viewStore: viewStore, direction: Direction.horizontal, maxDistance: joystickMaxDragDistance))
                        }
                        .frame(maxWidth: .infinity, alignment: .bottomLeading)
                        
                        ZStack(alignment: .center) {
                            RoundedRectangle(cornerRadius: joystickRectangleShort / 2, style: .continuous)
                                .fill(Color.black)
                                .frame(width: joystickRectangleShort, height: joystickRectangleLong)
                            Circle()
                                .fill(Color.blue)
                                .frame(width: joystickDiameter, height: joystickDiameter)
                                .modifier(DraggableModifier(viewStore: viewStore, direction: Direction.vertical, maxDistance: joystickMaxDragDistance))
                        }
                        .frame(maxWidth: .infinity, alignment: .bottomTrailing)
                        .padding(.trailing, joystickRectangleLong/4)
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding()
                }
            }
        }
    }
}

// MARK: - UI Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let leftJoystick = JoystickState(direction: Direction.horizontal)
        let rightJoystick = JoystickState(direction: Direction.vertical)
        
        let store = Store(
            initialState: CruiseState(
                horizontalJoystick: leftJoystick,
                verticalJoystick: rightJoystick),
            reducer: cruiseReducer,
            environment: CruiseEnvironment(
                apiClient: ApiClient.live,
                mainQueue: DispatchQueue.main.eraseToAnyScheduler()
            )
        )
        
        Group {
            ContentView(store: store)
                .previewLayout(.fixed(width: 1024, height: 768))
        } // iPad mini
    }
}
