typedef AttributeIndexGenF = Stream<int> Function(int upTo);

Stream<int> attributeIndexGenerator(int upTo) async* {
  int max = upTo;
  int nextInt = 0;
  while (max >= 0) {
    // 'yield' suspends the function
    yield nextInt++;
  }

  max--;
}
