//
//  Created by Антон Лобанов on 16.02.2021.
//

import UIKit
import ALSegmentView

final class HeaderView: UIView
{
    init() {
        super.init(frame: .zero)
        let innerView = UILabel()
        innerView.text = "Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello"
        innerView.font = .systemFont(ofSize: 48)
        innerView.numberOfLines = 0
        innerView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(innerView)
        self.backgroundColor = .random
        NSLayoutConstraint.activate([
            innerView.topAnchor.constraint(equalTo: self.topAnchor),
            innerView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            innerView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            innerView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ContentView: UIView, IALSegmentContentView
{
    var onSegmentScroll: (() -> Void)?
    var segmentScrollView: IALCollaborativeScroll { self.collectionView }
    
    private(set) lazy var collectionViewLayout = UICollectionViewFlowLayout()
    private(set) lazy var collectionView = ALCollaborativeCollectionView(
        frame: .zero,
        collectionViewLayout: self.collectionViewLayout
    )

    init() {
        super.init(frame: .zero)
        self.collectionViewLayout.sectionInset.top = 20
        self.collectionViewLayout.sectionInset.bottom = 20
        self.collectionViewLayout.minimumLineSpacing = 20
        self.collectionViewLayout.scrollDirection = .vertical
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.backgroundColor = .clear
        self.collectionView.register(
            UICollectionViewCell.self,
            forCellWithReuseIdentifier: String(describing: UICollectionViewCell.self)
        )
        self.addSubview(self.collectionView)
        NSLayoutConstraint.activate([
            self.collectionView.topAnchor.constraint(equalTo: self.topAnchor),
            self.collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ContentView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        Bool.random() ? 1 : 10
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: String(describing: UICollectionViewCell.self),
            for: indexPath
        )
        cell.layer.cornerRadius = 20
        cell.backgroundColor = .random
        return cell
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        .init(width: collectionView.frame.size.width - 40, height: 300)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.onSegmentScroll?()
    }
}

final class ViewController: UIViewController
{
    private lazy var segmentView: ALSegmentView = {
        let view = ALSegmentView(
            headerView: HeaderView(),
            segments: Array(0...2).map {
                ALSegment("\($0)") { ContentView() }
            },
            barStyles: .init(height: 42,
                             font: .systemFont(ofSize: 14, weight: .regular),
                             color: .black,
                             selectedColor: .systemBlue,
                             borderColor: .darkGray,
                             backgroundColor: .cyan,
                             borderHeight: 2)
        )
        return view
    }()
    
    override func loadView() {
        self.title = "Hello"
        self.view = self.segmentView
        self.segmentView.backgroundColor = .brown
    }
}

// -

extension UIColor {
    static var random: UIColor {
        return UIColor(red: .random(in: 0...1),
                       green: .random(in: 0...1),
                       blue: .random(in: 0...1),
                       alpha: 1.0)
    }
}
