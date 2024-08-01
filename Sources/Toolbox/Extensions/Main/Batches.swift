extension Sequence {
  func batches(by predicate: ([Element], Element) -> Bool) -> [[Element]] {
    var all = [[Element]]()
    var batch = [Element]()
    var iterator = makeIterator()
    while let item = iterator.next() {
      if !predicate(batch, item) {
        all.append(batch)
        batch = [Element]()
      }
      batch.append(item)
    }
    all.append(batch)
    return all
  }

  internal func split(batchSize: Int) -> [[Element]] {
    batches { batch, _ in batch.count < batchSize }
  }
}
