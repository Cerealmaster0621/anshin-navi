import SwiftUI
import UIKit

class FilterDrawerView: UIView {
    // MARK: - Properties
    private let currentAnnotationType: CurrentAnnotationType
    private let drawerWidth: CGFloat = UIScreen.main.bounds.width * 0.85
    private var originalCenter: CGPoint = .zero
    
    // UI Elements
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.15
        view.layer.shadowRadius = 10
        view.layer.shadowOffset = CGSize(width: -2, height: 0)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Initialization
    init(currentAnnotationType: CurrentAnnotationType) {
        self.currentAnnotationType = currentAnnotationType
        super.init(frame: .zero)
        setupView()
        setupFilterContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupView() {
        backgroundColor = .clear
        
        addSubview(containerView)
        containerView.addSubview(headerView)
        headerView.addSubview(titleLabel)
        containerView.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        NSLayoutConstraint.activate([
            // Container View
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.widthAnchor.constraint(equalToConstant: drawerWidth),
            
            // Header View
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            // Title Label
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Content Stack View
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
        
        // Add pan gesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        containerView.addGestureRecognizer(panGesture)
    }
    
    private func setupFilterContent() {
        switch currentAnnotationType {
        case .shelter:
            setupShelterFilter()
        case .none:
            break
        // Add more cases as needed
        }
    }
    
    private func setupShelterFilter() {
        titleLabel.text = "避難所フィルター"
        // Add shelter-specific filter UI elements to contentStackView
        // This will be implemented later
    }
    
    // MARK: - Actions
    @objc private func dismissDrawer() {
        UIView.animate(withDuration: 0.3, animations: {
            self.containerView.transform = CGAffineTransform(translationX: self.drawerWidth, y: 0)
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: containerView)
        
        switch gesture.state {
        case .began:
            originalCenter = containerView.center
        case .changed:
            if translation.x <= 0 { return }
            containerView.center.x = originalCenter.x + translation.x
        case .ended:
            let velocity = gesture.velocity(in: containerView)
            if velocity.x > 500 || translation.x > drawerWidth / 2 {
                dismissDrawer()
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.containerView.center = self.originalCenter
                }
            }
        default:
            break
        }
    }
    
    // MARK: - Public Methods
    func show(in view: UIView) {
        frame = view.bounds
        view.addSubview(self)
        
        containerView.transform = CGAffineTransform(translationX: drawerWidth, y: 0)
        UIView.animate(withDuration: 0.3) {
            self.containerView.transform = .identity
        }
    }
}
