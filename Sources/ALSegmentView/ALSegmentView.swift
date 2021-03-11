//
//  Created by Антон Лобанов on 20.02.2021.
//

import UIKit

public final class ALSegmentView: UIView
{
    public var onMainScroll: ((CGFloat) -> Void)?
    
    // MARK: - Views

    private lazy var headerContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var barView: ALSegmentBarView = {
        let view = ALSegmentBarView(styles: self.barStyles, segments: self.segments.map { $0.title })
        view.translatesAutoresizingMaskIntoConstraints = false
        view.onTapOnSegment = { [weak self] in
            self?.pageCollectionView.scrollToItem(
                at: IndexPath(item: $0, section: 0),
                at: .centeredHorizontally,
                animated: true
            )
        }
        return view
    }()
    
    private lazy var mainScrollView: UIScrollView = {
        let scrollView = ALCollaborativeScrollView()
        scrollView.backgroundColor = .clear
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        scrollView.alwaysBounceVertical = true
        if let refreshControl = self.refreshControl {
            if #available(iOS 10.0, *) {
                scrollView.refreshControl = refreshControl
            }
            else {
                scrollView.addSubview(refreshControl)
            }
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
        collectionView.register(ALSegmentBarView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: String(describing: ALSegmentBarView.self))
        collectionView.register(UICollectionViewCell.self,
                                forCellWithReuseIdentifier: String(describing: UICollectionViewCell.self))
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isPagingEnabled = true
        collectionView.delegate = self
        collectionView.dataSource = self
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        return collectionView
    }()
    
    // MARK: - Constraints
    
    private lazy var headerHeightConstraint = self.headerContainerView.heightAnchor.constraint(
        equalToConstant: self.barStyles.height
    )
    
    // MARK: - Use
    
    private var currentNestedScrollView: UIScrollView? {
        guard let currentCell = self.pageCollectionView.visibleCells
                .first(where: { $0.frame.origin.x == self.pageCollectionView.contentOffset.x }),
              let currentIndex = self.pageCollectionView.indexPath(for: currentCell)?.item
        else {
            return nil
        }
        return self.segments[currentIndex].content.scrollView
    }
    
    private var lastNestedScrollView: UIScrollView?

    private let headerView: UIView?
    private let refreshControl: UIRefreshControl?
    private let segments: [ALSegment]
    private let barStyles: ALSegmentBarStyles
    
    // MARK: - Initialization
    
    public init(
        headerView: UIView? = nil,
        segments: [ALSegment],
        barStyles: ALSegmentBarStyles,
        refreshControl: UIRefreshControl? = nil
    ) {
        self.headerView = headerView
        self.refreshControl = refreshControl
        self.segments = segments
        self.barStyles = barStyles
        super.init(frame: .zero)
        self.initializeView()
        self.initializeLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.layoutHeader()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.layoutHeader()
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == self.mainScrollView {
            let subview = self.pageCollectionView.hitTest(point, with: event)
            return subview?.isKind(of: UIControl.self) ?? false ? subview : view
        }
        return view
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
        contentView.onScroll = { [weak self] in self?.syncMainScrollIfNeeded() }
        contentView.scrollView.alwaysBounceVertical = true
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
        if scrollView == self.pageCollectionView { self.barView.didHorizontalScroll(with: scrollView.contentOffset) }
    }
}

// MARK: - Private

private extension ALSegmentView
{
    func layoutHeader() {
        let headerHeight = (self.headerView?.systemLayoutSizeFitting(
            .init(width: self.frame.width, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height ?? .zero) + self.barStyles.height
        self.headerHeightConstraint.constant = headerHeight
        self.segments.map { $0.content.scrollView }.forEach {
            $0.contentInset = .init(top: headerHeight, left: 0, bottom: 0, right: 0)
            if #available(iOS 11.1, *) {
                $0.verticalScrollIndicatorInsets = .init(top: headerHeight, left: 0, bottom: 0, right: 0)
            } else {
                $0.scrollIndicatorInsets = .init(top: headerHeight, left: 0, bottom: 0, right: 0)
            }
        }
        self.mainScrollView.contentSize.height = headerHeight + self.frame.height
    }
    
    func syncMainScrollIfNeeded() {
        guard let nestedScrollView = self.currentNestedScrollView else { return }
        let ctx = (
            headerH: self.headerHeightConstraint.constant,
            nestedY: nestedScrollView.contentOffset.y,
            barHeight: self.barStyles.height
        )
        let minY = ctx.headerH + ctx.nestedY
        let maxY = ctx.headerH - ctx.barHeight
        let mainY = ctx.headerH == ctx.barHeight ? maxY : min(minY, maxY)
        self.mainScrollView.contentOffset.y = mainY
        self.lastNestedScrollView = nestedScrollView
        self.onMainScroll?(mainY)
    }
    
    func syncNestedScrollIfNeeded() {
        guard let nestedScrollView = self.lastNestedScrollView,
              self.headerHeightConstraint.constant > self.barStyles.height
        else {
            return
        }
        let ctx = (
            nestedY: nestedScrollView.contentOffset.y,
            barHeight: self.barStyles.height
        )
        self.segments
            .map { $0.content.scrollView }
            .filter { $0 != nestedScrollView }
            .forEach {
                if ctx.nestedY > 0 && $0.contentOffset.y < 0 { $0.contentOffset.y = -ctx.barHeight }
                if ctx.nestedY < 0 { $0.contentOffset.y = ctx.nestedY }
            }
    }
}

// MARK: - Configure

private extension ALSegmentView
{
    func initializeView() {
        self.addSubview(self.pageCollectionView)
        self.addSubview(self.mainScrollView)
        self.mainScrollView.addSubview(self.headerContainerView)
        self.headerContainerView.addSubview(self.barView)
        if let headerView = self.headerView {
            headerView.translatesAutoresizingMaskIntoConstraints = false
            self.headerContainerView.addSubview(headerView)
        }
    }
    
    func initializeLayout() {
        self.headerHeightConstraint.priority = .defaultLow
        NSLayoutConstraint.activate([
            self.mainScrollView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
            self.mainScrollView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor),
            self.mainScrollView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor),
            self.mainScrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
        NSLayoutConstraint.activate([
            self.headerContainerView.topAnchor.constraint(equalTo: self.mainScrollView.topAnchor),
            self.headerContainerView.leadingAnchor.constraint(equalTo: self.mainScrollView.leadingAnchor),
            self.headerContainerView.trailingAnchor.constraint(equalTo: self.mainScrollView.trailingAnchor),
            self.headerContainerView.widthAnchor.constraint(equalTo: self.mainScrollView.widthAnchor),
            self.headerHeightConstraint,
        ])
        if let headerView = self.headerView {
            NSLayoutConstraint.activate([
                headerView.topAnchor.constraint(equalTo: self.headerContainerView.topAnchor),
                headerView.leadingAnchor.constraint(equalTo: self.headerContainerView.leadingAnchor),
                headerView.trailingAnchor.constraint(equalTo: self.headerContainerView.trailingAnchor),
                self.barView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
                self.barView.leadingAnchor.constraint(equalTo: self.headerContainerView.leadingAnchor),
                self.barView.trailingAnchor.constraint(equalTo: self.headerContainerView.trailingAnchor),
                self.barView.bottomAnchor.constraint(equalTo: self.headerContainerView.bottomAnchor),
                self.barView.heightAnchor.constraint(equalToConstant: self.barStyles.height),
            ])
        }
        else {
            NSLayoutConstraint.activate([
                self.barView.topAnchor.constraint(equalTo: self.headerContainerView.topAnchor),
                self.barView.leadingAnchor.constraint(equalTo: self.headerContainerView.leadingAnchor),
                self.barView.trailingAnchor.constraint(equalTo: self.headerContainerView.trailingAnchor),
                self.barView.bottomAnchor.constraint(equalTo: self.headerContainerView.bottomAnchor),
                self.barView.heightAnchor.constraint(equalToConstant: self.barStyles.height),
            ])
        }
        NSLayoutConstraint.activate([
            self.pageCollectionView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
            self.pageCollectionView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor),
            self.pageCollectionView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor),
            self.pageCollectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
    }
}
