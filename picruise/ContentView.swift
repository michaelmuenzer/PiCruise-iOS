import ComposableArchitecture
import SwiftUI

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
    
    case connect
    case connectResponse(Result<Void, ApiClient.Failure>)
    
    //TODO: Add disconnect + response
    
    case navigateHorizontal(Float)
    case navigateVertical(Float)
}

struct CruiseEnvironment {
    var apiClient: ApiClient
    var mainQueue: AnySchedulerOf<DispatchQueue>
}

// MARK: - Reducer
let cruiseReducer = Reducer<CruiseState, CruiseAction, CruiseEnvironment> {
    state, action, environment in
    switch action {
    
    case .connect:
        state.connectionRequestInFlight = true
        
        return environment.apiClient
            .connect()
            .fireAndForget()
    
    case let .connectResponse(.success(response)):
        state.connectionRequestInFlight = false
        state.isConnected = true
        return .none
    
    case .connectResponse(.failure):
        state.connectionRequestInFlight = false
        return .none
        
    case let .navigateHorizontal(distance):
        var normalizedAngle = normalizeJoystickDistance(distance: -distance)
        
        return environment.apiClient
            .angle(normalizedAngle)
            .fireAndForget()

    case let .navigateVertical(distance):
        var normalizedSpeed = normalizeJoystickDistance(distance: -distance)
        
        return environment.apiClient
            .speed(normalizedSpeed)
            .fireAndForget()
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
                    viewStore.send(CruiseAction.navigateHorizontal(Float(distance)))
                } else {
                    distance = draggedOffset.height
                    viewStore.send(CruiseAction.navigateVertical(Float(distance)))
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
let joystickRectangleLong: CGFloat = 200
let joystickRectangleShort: CGFloat = 50

struct ContentView: View {
    let store: Store<CruiseState, CruiseAction>
    
    let joystickPadding: CGFloat = 10
    var joystickDiameter: CGFloat
    var joystickMaxDragDistance: CGFloat
    
    let videoStream = "http://raspberrypi.local:8080/stream/video.mjpeg"

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
                        Button(viewStore.isConnected ? "Disconnect" : "Connect") { viewStore.send(.connect) }
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

func normalizeJoystickDistance(distance: Float) -> Float{
    var normalizedDistance = distance / (Float(joystickRectangleLong - joystickRectangleShort) / 2)
    normalizedDistance = Float.maximum(-1.0, Float.minimum(1.0, normalizedDistance))
    print(normalizedDistance)
    
    return normalizedDistance
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
