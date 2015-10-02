import Foundation
import ATPathSpec

public final class TagEvidenceTree: CustomStringConvertible {
    
    var filesToEvidence = [ProjectFile: [TagEvidence]]()
    var tagsToFiles = [Tag: Set<ProjectFile>]()
    
    public func replaceEvidence(file file: ProjectFile, newEvidence: [TagEvidence]) {
        deleteEvidence(file: file)
        filesToEvidence[file] = newEvidence
        for claim in newEvidence {
            if tagsToFiles[claim.tag] == nil {
                tagsToFiles[claim.tag] = Set<ProjectFile>()
            }
            tagsToFiles[claim.tag]?.insert(file)
        }
    }
    
    public func deleteEvidence(file file: ProjectFile) {
        filesToEvidence[file] = nil
    }
    
    public var description: String  {
        var lines : [String] = []
        let sortedFiles = filesToEvidence.keys.sort { $0.relativePath < $1.relativePath }
        for file in sortedFiles {
            let evidence = filesToEvidence[file]!
            let evidenceString = evidence.map { $0.description }.joinWithSeparator(", ")
            let line = "\(file.relativePath) -> \(evidenceString)"
            lines.append(line)
        }
        return lines.joinWithSeparator("\n");
    }
    
    public func findCoveringFoldersForTag(tag: Tag) -> [String] {
        print("findCoveringFoldersForTag(\(tag.name)):")
        var initialFolders: Set<String> = []
        for file in tagsToFiles[tag] ?? [] {
            initialFolders.insert(file.relativePath.stringByDeletingLastPathComponent)
        }
        print("  initialFolders = \(initialFolders)")
        
        var nextFolders: Set<String> = initialFolders
        var folderChildren: [String: Set<String>] = [:]
        while !nextFolders.isEmpty {
            let thisFolders = nextFolders
            nextFolders = []
            
            for folder in thisFolders {
                if folder != "" {
                    print("  visiting \(folder)")
                    let parent = folder.stringByDeletingLastPathComponent
                    if folderChildren[parent] == nil {
                        folderChildren[parent] = [folder]
                        nextFolders.insert(parent)
                    } else {
                        folderChildren[parent]!.insert(folder)
                    }
                }
            }
        }

        var junctions: [String] = []
        print("  collecting junctions")
        _collectJunctionPoints("", folderChildren: folderChildren, initialFolders: initialFolders, junctions: &junctions)
        print("  result = \(junctions)")
        return junctions
    }
    
    private func _collectJunctionPoints(folder: String, folderChildren: [String: Set<String>], initialFolders: Set<String>, inout junctions: [String]) {
        if initialFolders.contains(folder) {
            print("    folder with leaf files \(folder)")
            junctions.append(folder)
            // don't descend into children
        } else {
            let children = folderChildren[folder] ?? []
            if folder != "" && children.count >= 2 {
                print("    non-root junction folder \(folder)")
                junctions.append(folder)
                // don't descend into children for now, although it would return useful alternative folders
            } else {
                for child in children {
                    _collectJunctionPoints(child, folderChildren: folderChildren, initialFolders: initialFolders, junctions: &junctions)
                }
            }
        }
    }
    
}
