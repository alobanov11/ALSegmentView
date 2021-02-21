//
//  Created by Антон Лобанов on 20.02.2021.
//

import UIKit

public final class ALSegmentView: UIView
{
    // MARK: - Views

    private lazy var headerContainerView: UIView = {
        let view = ALSegmentHeaderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var mainScrollView: UIScrollView = {
        let scrollView = ALCollaborativeScrollView()
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        scrollView.backgroundColor = .clear
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        scrollView.alwaysBounceVertical = true
        if #available(iOS 13.0, *) {
            scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        return scrollView
    }()
    
    private lazy var pageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: String(describing: UICollectionViewCell.self))
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.isPagingEnabled = true
        collectionView.delegate = self
        collectionView.dataSource = self
        if #available(iOS 13.0, *) {
            collectionView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        return collectionView
    }()
    
    // MARK: - Constraints
    
    private lazy var headerHeightConstraint = self.headerContainerView.heightAnchor.constraint(equalToConstant: 0)
    
    // MARK: - Use
    
    private var currentNestedScrollView: UIScrollView? {
        guard let currentCell = self.pageCollectionView.visibleCells
                .first(where: { $0.frame.origin.x == self.pageCollectionView.contentOffset.x }),
              let currentIndex = self.pageCollectionView.indexPath(for: currentCell)?.item
        else {
            return nil
        }
        return self.segments[currentIndex].content.segmentScrollView
    }
    
    private var lastNestedScrollView: UIScrollView?
    
    private let segments: [ALSegment]
    
    // MARK: - Initialization
    
    public init(
        headerView: UIView? = nil,
        segments: [ALSegment]
    ) {
        self.segments = segments
        super.init(frame: .zero)
        self.initializeView(with: headerView)
        self.initializeContraints(with: headerView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.layoutHeaderIfNeeded()
    }
}

// MARK: - Public

public extension ALSegmentView
{
}

// MARK: - UICollectionView

extension ALSegmentView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    public func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        self.segments.count
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: String(describing: UICollectionViewCell.self),
            for: indexPath
        )
        let contentView = self.segments[indexPath.item].content
        contentView.onSegmentScroll = { [weak self] in self?.syncMainScrollIfNeeded() }
        contentView.segmentScrollView.contentInset.top = self.headerHeightConstraint.constant
        contentView.segmentScrollView.alwaysBounceVertical = true
        contentView.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
        ])
        return cell
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        DispatchQueue.main.async { self.syncNestedScrollIfNeeded() }
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        collectionView.frame.size
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.syncMainScrollIfNeeded()
    }
}

// MARK: - Private

private extension ALSegmentView
{
    func layoutHeaderIfNeeded() {
        guard let headerView = self.headerContainerView.subviews.first else { return }
        let headerSize = headerView.systemLayoutSizeFitting(
            .init(width: self.frame.width, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        self.headerHeightConstraint.constant = headerSize.height
        self.segments.map { $0.content.segmentScrollView }.forEach {
            $0.contentInset.top = headerSize.height
            $0.scrollIndicatorInsets.top = headerSize.height
        }
        self.mainScrollView.contentSize.height = headerSize.height + self.frame.height
    }
    
    func syncMainScrollIfNeeded() {
        guard let nestedScrollView = self.currentNestedScrollView else { return }
        let ctx = (
            headerH: self.headerHeightConstraint.constant,
            nestedY: nestedScrollView.contentOffset.y
        )
        self.mainScrollView.contentOffset.y = ctx.headerH + ctx.nestedY
        self.lastNestedScrollView = nestedScrollView
    }
    
    func syncNestedScrollIfNeeded() {
        guard let nestedScrollView = self.lastNestedScrollView else { return }
        let ctx = (
            _: 0,
            nestedY: nestedScrollView.contentOffset.y
        )
        self.segments
            .map { $0.content.segmentScrollView }
            .filter { $0 != nestedScrollView }
            .forEach {
                if ctx.nestedY > 0 && $0.contentOffset.y < 0 { $0.contentOffset.y = 0 }
                if ctx.nestedY < 0 { $0.contentOffset.y = ctx.nestedY }
            }
    }
}

// MARK: - Configure

private extension ALSegmentView
{
    func initializeView(with headerView: UIView?) {
        self.addSubview(self.mainScrollView)
        self.addSubview(self.pageCollectionView)
        self.mainScrollView.addSubview(self.headerContainerView)
        if let headerView = headerView {
            headerView.translatesAutoresizingMaskIntoConstraints = false
            self.headerContainerView.addSubview(headerView)
        }
    }
    
    func initializeContraints(with headerView: UIView?) {
        NSLayoutConstraint.activate([
            self.mainScrollView.topAnchor.constraint(equalTo: self.topAnchor),
            self.mainScrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.mainScrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.mainScrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
        NSLayoutConstraint.activate([
            self.headerContainerView.topAnchor.constraint(equalTo: self.mainScrollView.topAnchor),
            self.headerContainerView.leadingAnchor.constraint(equalTo: self.mainScrollView.leadingAnchor),
            self.headerContainerView.trailingAnchor.constraint(equalTo: self.mainScrollView.trailingAnchor),
            self.headerContainerView.widthAnchor.constraint(equalTo: self.mainScrollView.widthAnchor),
            self.headerHeightConstraint,
        ])
        if let headerView = headerView {
            NSLayoutConstraint.activate([
                headerView.topAnchor.constraint(equalTo: self.headerContainerView.topAnchor),
                headerView.leadingAnchor.constraint(equalTo: self.headerContainerView.leadingAnchor),
                headerView.trailingAnchor.constraint(equalTo: self.headerContainerView.trailingAnchor),
                headerView.bottomAnchor.constraint(equalTo: self.headerContainerView.bottomAnchor),
            ])
        }
        NSLayoutConstraint.activate([
            self.pageCollectionView.topAnchor.constraint(equalTo: self.topAnchor),
            self.pageCollectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.pageCollectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.pageCollectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.pageCollectionView.heightAnchor.constraint(equalTo: self.heightAnchor),
        ])
    }
}
