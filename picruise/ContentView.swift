import SwiftUI
import Alamofire

let host = "http://raspberrypi.local"

enum Direction {
    case vertical
    case horizontal
}

class JoystickViewModel : ObservableObject{
    let direction: Direction
    let maxDistance: CGFloat
    @Published var draggedOffset: CGSize = .zero
    
    init(direction: Direction, maxDistance: CGFloat) {
        self.direction = direction
        self.maxDistance = maxDistance
    }
}

struct DraggableModifier : ViewModifier {
    @ObservedObject var viewModel: JoystickViewModel

    func body(content: Content) -> some View {
        content
        .offset(
            CGSize(width: viewModel.direction == .vertical ?
                    0 : max(-viewModel.maxDistance, min(viewModel.maxDistance, viewModel.draggedOffset.width)),
                   
                   height: viewModel.direction == .horizontal ?
                    0 : max(-viewModel.maxDistance, min(viewModel.maxDistance, viewModel.draggedOffset.height))
            )
        )
        .gesture(
            DragGesture()
            .onChanged { value in
                self.viewModel.draggedOffset = value.translation
                /*if(self.viewModel.draggedOffset < 0) {
                    AF.request("\(host)/left", method: .post)
                } else {*/
                let api = "\(host):8082"
                AF.request("\(api)/right", method: .post).response { response in debugPrint(response)
                }
                //}
            }
            .onEnded { value in
                self.viewModel.draggedOffset = .zero
            }
        )
    }
}

struct ContentView: View {
    let joystickRectangleLong: CGFloat = 200
    let joystickRectangleShort: CGFloat = 50
    let joystickPadding: CGFloat = 10
    
    var joystickDiameter: CGFloat
    var joystickMaxDragDistance: CGFloat
    
    var videoStream = host + ":8080/stream/video.mjpeg"
    @ObservedObject var leftJoystick : JoystickViewModel
    @ObservedObject var rightJoystick : JoystickViewModel

    init() {
        joystickDiameter = joystickRectangleShort - joystickPadding
        joystickMaxDragDistance = (joystickRectangleLong-joystickDiameter-joystickPadding)/2
        
        leftJoystick = JoystickViewModel(
               direction: Direction.horizontal,
               maxDistance: joystickMaxDragDistance)
        
        rightJoystick = JoystickViewModel(
               direction: Direction.vertical,
               maxDistance: joystickMaxDragDistance)
    }
    
    var body: some View {
        ZStack {
            MjpegWebView(url: videoStream)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
            HStack(alignment: .center) {
                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: joystickRectangleShort / 2, style: .continuous)
                        .fill(Color.black)
                        .frame(width: joystickRectangleLong, height: joystickRectangleShort)
                    Circle()
                        .fill(Color.blue)
                        .frame(width: joystickDiameter, height: joystickDiameter)
                        .modifier(DraggableModifier(viewModel: leftJoystick))
                }
                .frame(maxWidth: .infinity, alignment: .bottomLeading)
                
                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: joystickRectangleShort / 2, style: .continuous)
                        .fill(Color.black)
                        .frame(width: joystickRectangleShort, height: joystickRectangleLong)
                    Circle()
                        .fill(Color.blue)
                        .frame(width: joystickDiameter, height: joystickDiameter)
                        .modifier(DraggableModifier(viewModel: rightJoystick))
                }
                .frame(maxWidth: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, joystickRectangleLong/4)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewLayout(.fixed(width: 1024, height: 768))
        } // iPad mini
    }
}
