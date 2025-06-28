//
//  ViewController.swift
//  MemoryLayout
//
//  Created by imurashov on 27.06.2025.
//

import Cocoa

// Отступ от краев окна
fileprivate let padding: CGFloat = 20

// Набор данных для отображения
struct MemoryLayoutRepresentation {
    let size: Int
    let stride: Int
    let alignment: Int
}

// Выбираем что подсвечивать
enum SelectedProperty {
    case size
    case stride
    case alignment
}

final class ViewController: NSViewController {
    
    // Структура, MemoryLayout которой мы рассматриваем
    struct Foo {
        let c: Int16
        let b: Int8
    }
    
    // Заголовки режимов отображения
    private let stackView: NSStackView = {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        return stackView
    }()
    
    private let sizeLabel: HoverTextField = HoverTextField(labelWithString: "Size")
    private let strideLabel: HoverTextField = HoverTextField(labelWithString: "Stride")
    private let alignmentLabel: HoverTextField = HoverTextField(labelWithString: "Alignment")
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let representationView = view as! RepresentationView
        
        sizeLabel.setup {
            representationView.selectedProperty = $0 ? .size : nil
        }
        
        strideLabel.setup {
            representationView.selectedProperty = $0 ? .stride : nil
        }
        
        alignmentLabel.setup {
            representationView.selectedProperty = $0 ? .alignment : nil
        }
        
        stackView.addArrangedSubview(sizeLabel)
        stackView.addArrangedSubview(strideLabel)
        stackView.addArrangedSubview(alignmentLabel)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: padding),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding)
        ])
        
        representationView.memoryLayout = MemoryLayoutRepresentation(
            size: MemoryLayout<Foo>.size,
            stride: MemoryLayout<Foo>.stride,
            alignment: MemoryLayout<Foo>.alignment
        )
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        view.updateTrackingAreas()
    }
}

// NSView в котором все рисуем
final class RepresentationView: NSView {
    
    private let byteSpacing: CGFloat = 10
    private let byteY: CGFloat = 40
    
    var memoryLayout: MemoryLayoutRepresentation?
    
    var selectedProperty: SelectedProperty? {
        didSet {
            needsDisplay = true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        guard let memoryLayout else {
            return
        }
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        context.setAlpha(0.7)
                        
        let spacing: CGFloat = byteSpacing * CGFloat(memoryLayout.stride - 1)
        let width: CGFloat = (safeAreaRect.width - (padding * 2) - spacing) / CGFloat(memoryLayout.stride)
                
        for i in 0..<memoryLayout.stride {
            let rectangle = NSRect(
                x: padding + (CGFloat(i) * width) + (CGFloat(i) * byteSpacing),
                y: byteY,
                width: width,
                height: 100
            )
            
            switch selectedProperty {
            case .size:
                if i < memoryLayout.size {
                    NSColor.systemRed.setFill()
                } else {
                    NSColor.lightGray.setFill()
                }
            case .stride:
                if i < memoryLayout.stride {
                    NSColor.systemBlue.setFill()
                } else {
                    NSColor.lightGray.setFill()
                }
            default:
                NSColor.lightGray.setFill()
            }
            
            NSBezierPath(rect: rectangle).fill()
        }
        
        if selectedProperty == .alignment {
            
            NSColor.systemGreen.setFill()
            
            let alignmentWidth: CGFloat = CGFloat(memoryLayout.alignment) * width + CGFloat(memoryLayout.alignment - 1) * byteSpacing

            for i in 0..<(memoryLayout.stride / memoryLayout.alignment) {
                let path = NSBezierPath()
                let start = NSPoint(x: padding + (CGFloat(i) * alignmentWidth) + (CGFloat(i) * byteSpacing), y: 20)
                let finish = NSPoint(x: start.x + alignmentWidth, y: start.y)
                path.move(to: start)
                path.line(to: finish)
                path.lineWidth = 2
                path.stroke()
            }
        }
        
        context.restoreGState()
    }
}

// NSTextField, реагирующий на наведение курсора
final class HoverTextField: NSTextField {
    
    private var trackingArea: NSTrackingArea!
    private var highlightHandler: ((Bool) -> Void)?
    
    func setup(highlightHandler: @escaping (Bool) -> Void) {
        self.highlightHandler = highlightHandler
        textColor = .systemGray
        font = NSFont.systemFont(ofSize: 16, weight: .medium)
        alignment = .center
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if trackingArea != nil {
            removeTrackingArea(trackingArea)
        }
        
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInActiveApp],
            owner: self,
            userInfo: nil
        )
        
        addTrackingArea(trackingArea)
    }
    
    override func mouseEntered(with event: NSEvent) {
        textColor = .systemMint
        highlightHandler?(true)
    }
    
    override func mouseExited(with event: NSEvent) {
        textColor = .systemGray
        highlightHandler?(false)
    }
}
