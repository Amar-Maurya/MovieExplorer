//
//  SearchVC+CollectionExt.swift
//  MovieExplorer
//
//  Created by 2674143 on 27/07/25.
//
import UIKit

extension SearchViewController {
    
    func configureCollectionView() {
        collectionView.register(UINib(nibName: CellConstants.searchCVCell, bundle: nil),
                                forCellWithReuseIdentifier: CellConstants.searchCVCell)
        collectionView.register(
            UINib(nibName: CellConstants.headerReusableView, bundle: nil),
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: CellConstants.headerReusableView)
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.frame.width / 3 - 8, height: 200)
        layout.sectionInset = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        layout.headerReferenceSize = CGSize(width: view.frame.width, height: 40)
        collectionView.collectionViewLayout = layout
        collectionView.delegate = self
    }

     func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<SearchMovieSection, SearchMovieModel>(collectionView: collectionView) {
            collectionView, indexPath, movie in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellConstants.searchCVCell, for: indexPath) as? SearchCVCell else {
                return UICollectionViewCell()
            }
            cell.setupCell(with: movie)
            return cell
        }
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            switch kind {
            case UICollectionView.elementKindSectionHeader:
                let header = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: CellConstants.headerReusableView,
                    for: indexPath
                ) as! HeaderReusableView
                
                let section = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
                header.setTitle(section.title)
                return header
                
            default:
                fatalError("Unsupported supplementary view kind: \(kind)")
            }
        }
        
    }

     func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<SearchMovieSection, SearchMovieModel>()
        
        if viewModel.isSearching {
            snapshot.appendSections([.searchResults])
            snapshot.appendItems(viewModel.searchResults, toSection: .searchResults)
        } else {
            snapshot.appendSections([.topRated])
            snapshot.appendItems(viewModel.topRatedMovies, toSection: .topRated)
        }

        dataSource.apply(snapshot, animatingDifferences: true)
    }

}
