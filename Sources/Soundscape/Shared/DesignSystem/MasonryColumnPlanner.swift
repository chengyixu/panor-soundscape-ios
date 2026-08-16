enum MasonryColumnPlanner {
    static func columns<Item>(
        for items: [Item],
        estimatedHeight: KeyPath<Item, Double>,
        spacing: Double = 14
    ) -> [[Item]] {
        var columns: [[Item]] = [[], []]
        var heights = [0.0, 0.0]

        for item in items {
            let column = heights[0] <= heights[1] ? 0 : 1
            columns[column].append(item)
            heights[column] += item[keyPath: estimatedHeight] + spacing
        }

        return columns
    }
}
