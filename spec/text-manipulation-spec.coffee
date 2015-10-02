_ = require 'underscore-plus'
ListEdit = require '../lib/list-edit'
TextManipulation = require '../lib/text-manipulation'

describe 'TextManipulation', ->
  sourceFragment = 'Data 1 2 3'
  leadingWhitespace = ' ' #'\n\n\t '
  trailingWhitespace = ' ' #'\n\n\t '
  describe 'stripLeadingWhitespace', ->
    it 'strips leading whitespace', ->
    expect(TextManipulation.stripLeadingWhitespace (leadingWhitespace+sourceFragment+trailingWhitespace))
      .toEqual(sourceFragment+trailingWhitespace)
    it 'is identity when there is no leading whitespace', ->
    expect(TextManipulation.stripLeadingWhitespace (sourceFragment+trailingWhitespace))
      .toEqual(sourceFragment+trailingWhitespace)
    it 'handles whitespace-only string', ->
    expect(TextManipulation.stripLeadingWhitespace (leadingWhitespace+trailingWhitespace))
      .toEqual('')

  describe 'stripTrailingWhitespace', ->
    it 'strips trailing whitespace', ->
    expect(TextManipulation.stripTrailingWhitespace (leadingWhitespace+sourceFragment+trailingWhitespace))
      .toEqual(leadingWhitespace+sourceFragment)
    it 'is identity when there is no trailing whitespace', ->
    expect(TextManipulation.stripTrailingWhitespace (leadingWhitespace+sourceFragment))
      .toEqual(leadingWhitespace+sourceFragment)
    it 'handles whitespace-only string', ->
    expect(TextManipulation.stripTrailingWhitespace (leadingWhitespace+trailingWhitespace))
      .toEqual('')

  describe 'findMatchingOpeningBracket', ->
    #             012345678901
    bufferText = '[1,[1,2,[]]]'
    it 'handles index at end of nested list', ->
      expect(TextManipulation.findMatchingOpeningBracket bufferText, [], 11, false)
       .toEqual({bracketIx: 0, ranges: [ [1,3] ]})
    it 'handles index at end of nested list contents', ->
      expect(TextManipulation.findMatchingOpeningBracket bufferText, [], 10, false)
       .toEqual({bracketIx: 3, ranges: [ [4,8] ]})
    it 'handles index at start of nested nested list contents', ->
      expect(TextManipulation.findMatchingOpeningBracket bufferText, [], 9, false)
       .toEqual({bracketIx: 8, ranges: [  ]})
    it 'handles index at start of nested nested list', ->
      expect(TextManipulation.findMatchingOpeningBracket bufferText, [], 8, false)
       .toEqual({bracketIx: 3, ranges: [ [4,8] ]})
    it 'handles index at start of list contents', ->
      expect(TextManipulation.findMatchingOpeningBracket bufferText, [], 1, false)
       .toEqual({bracketIx: 0, ranges: [  ]})

  describe 'findMatchingClosingBracket', ->
    #             01234567890123
    bufferText = '[1,[[],2,3],4]'
    it 'handles index at start of list contents', ->
      expect(TextManipulation.findMatchingClosingBracket bufferText, [], 1, false)
       .toEqual({bracketIx: 13, ranges: [ [1,3], [11,13] ]})
    it 'handles index at start of nested list', ->
      expect(TextManipulation.findMatchingClosingBracket bufferText, [], 3, false)
       .toEqual({bracketIx: 13, ranges: [ [11,13] ]})
    it 'handles index at start of nested list contents', ->
      expect(TextManipulation.findMatchingClosingBracket bufferText, [], 4, false)
       .toEqual({bracketIx: 10, ranges: [ [6,10] ]})
    it 'handles index at end of nested list', ->
      expect(TextManipulation.findMatchingClosingBracket bufferText, [], 11, false)
       .toEqual({bracketIx: 13, ranges: [ [11,13] ]})
    it 'handles index at start of list', ->
      expect(TextManipulation.findMatchingClosingBracket bufferText, [], 0, false)
       .toEqual(null)

  describe 'getEnclosingList', ->
    #             01234567890123
    bufferText = '[1,(a,b),2]'
    it 'works when surrounding a nested list', ->
      expect(TextManipulation.getEnclosingList bufferText, [], 3, 8)
        .toEqual({listRange: [1, 10], nonNestedRanges: [[1, 3], [8, 10]]})
    it 'works when inside a nested list', ->
      expect(TextManipulation.getEnclosingList bufferText, [], 5, 5)
        .toEqual({listRange: [4, 7], nonNestedRanges: [[4, 5], [5, 7]]})
    it 'fails on bracket mismatch', ->
      expect(TextManipulation.getEnclosingList '(  ]', 2, 2)
        .toEqual(null)

  describe 'getListContainingRange', ->
    #                       1         2         3         4
    #             01234567890123456789012345678901234567890123456789
    bufferText = '[one, f(a,b), two, {p1: [v1,v2], p2:v3}, three]'
    it 'handles range inside one element', ->
      expect(TextManipulation.getListContainingRange bufferText, [], [1, 1])
        .toEqual({listRange: [1, 46], nonNestedRanges : [[1, 7], [12, 19], [39, 46]]})
    it 'handles range starting inside one element and ending inside another element', ->
      expect(TextManipulation.getListContainingRange bufferText, [], [1, 15])
        .toEqual({listRange: [1, 46], nonNestedRanges : [[1, 7], [12, 19], [39, 46]]})
    it 'handles range starting in one nested list and ending in a nested list inside another nested list', ->
      expect(TextManipulation.getListContainingRange bufferText, [], [8, 25])
        .toEqual({listRange: [1, 46], nonNestedRanges : [[1, 7], [12, 19], [39, 46]]})

  describe 'getElementList', ->
    #             01234567890123
    bufferText = '{1,([],2,3),4}'

    it 'should return null when there is no enclosing list', ->
      expect(TextManipulation.getElementList bufferText, [], [0,0])
        .toEqual(null)

    it 'should return the elements of the enclosing list even when index is immediately after opening tag', ->
      expect((TextManipulation.getElementList bufferText, [], [1,1]).elts)
        .toEqual(_.map [ [1,2], [3,11], [12,13] ], (r) -> new TextManipulation.ListElement bufferText, r)

    it 'should return the elements of a nested list', ->
      expect((TextManipulation.getElementList bufferText, [], [4,4]).elts)
        .toEqual(_.map [ [4,6], [7,8], [9,10] ], (r) -> new TextManipulation.ListElement bufferText, r)

    it 'should return the elements (i.e. []) of an empty list', ->
      expect((TextManipulation.getElementList bufferText, [], [5,5]).elts)
        .toEqual( [] )

    it 'should allow empty ranges', ->
      expect((TextManipulation.getElementList '[ ,, ]', [], [1,1]).elts)
        .toEqual(_.map [ [1,2], [3,3], [4,5] ], (r) -> new TextManipulation.ListElement '[ ,, ]', r)

    it 'should allow empty ranges at start and end', ->
      expect((TextManipulation.getElementList '[, ,]', [], [1,1]).elts)
        .toEqual(_.map [ [1,1], [2,3], [4,4] ], (r) -> new TextManipulation.ListElement '[, ,]', r)

  describe 'getSelectionForRange', ->
    #                                            01234567890123456789012345
    listElts = (TextManipulation.getElementList '[   Inky , Dinky , Pinky  ]', [], [1,1]).elts

    it 'should select a single element when selection is inside the element', ->
      expect(TextManipulation.getSelectionForRange listElts, [5,5]).toEqual([0,1])

    it 'should select multiple elements when selection starts and ends inside these elements', ->
      expect(TextManipulation.getSelectionForRange listElts, [3,12]).toEqual([0,2])

    it 'should select a single element when selection surrounds the element', ->
      expect(TextManipulation.getSelectionForRange listElts, [3,9]).toEqual([0,1])

    it 'should select a all elements when selection surrounds all elements', ->
      expect(TextManipulation.getSelectionForRange listElts, [1,26]).toEqual([0,3])

    it 'should select an empty range when selection is in leading whitespace', ->
      expect(TextManipulation.getSelectionForRange listElts, [2,3]).toEqual([0,0])

    it 'should select an empty range when selection is in trailing whitespace', ->
      expect(TextManipulation.getSelectionForRange listElts, [24,25]).toEqual([3,3])

    it 'should select an empty range when selection surrounds single separator', ->
      expect(TextManipulation.getSelectionForRange listElts, [9,10]).toEqual([1,1])

    it 'should select a single element when selection surrounds the element and adjoining separators', ->
      expect(TextManipulation.getSelectionForRange listElts, [9,18]).toEqual([1,2])

  describe 'findRangeForIndex', ->
    ignoreRanges = [[1,2],[3,4],[5,6],[7,8],[9,10]]

    it 'handles index before ranges', ->
      expect(TextManipulation.findRangeForIndex ignoreRanges, 0)
        .toEqual(null)

    it 'handles index after ranges', ->
      expect(TextManipulation.findRangeForIndex ignoreRanges, 10)
        .toEqual(null)

    it 'handles index between ranges', ->
      expect(TextManipulation.findRangeForIndex ignoreRanges, 4)
        .toEqual(null)

    it 'handles index inside left-most range', ->
      expect(TextManipulation.findRangeForIndex ignoreRanges, 1)
        .toEqual([1,2])

    it 'handles index inside right-most range', ->
      expect(TextManipulation.findRangeForIndex ignoreRanges, 9)
        .toEqual([9,10])

    it 'handles index inside middle range', ->
      expect(TextManipulation.findRangeForIndex ignoreRanges, 5)
        .toEqual([5,6])

    it 'handles index inside range left of middle', ->
      expect(TextManipulation.findRangeForIndex [[1,2],[3,4],[5,6],[7,8]], 3)
        .toEqual([3,4])

  describe 'backwardSkipIgnored', ->
    ignoreRanges = [[1,2],[4,6],[8,10]]

    it 'handles index after ignore', ->
      expect(TextManipulation.backwardSkipIgnored ignoreRanges, 7)
        .toEqual(7)
    it 'handles index immediately after ignore', ->
      expect(TextManipulation.backwardSkipIgnored ignoreRanges, 6)
        .toEqual(6)
    it 'handles index inside ignore', ->
      expect(TextManipulation.backwardSkipIgnored ignoreRanges, 5)
        .toEqual(4)
    it 'handles index at start of ignore', ->
      expect(TextManipulation.backwardSkipIgnored ignoreRanges, 4)
        .toEqual(4)

  describe 'forwardSkipIgnored', ->
    ignoreRanges = [[1,2],[4,6],[8,10]]

    it 'handles index before ignore', ->
      expect(TextManipulation.forwardSkipIgnored ignoreRanges, 3)
        .toEqual(3)
    it 'handles index at start of ignore', ->
      expect(TextManipulation.forwardSkipIgnored ignoreRanges, 4)
        .toEqual(6)
    it 'handles index inside ignore', ->
      expect(TextManipulation.forwardSkipIgnored ignoreRanges, 5)
        .toEqual(6)
    it 'handles index immediately after ignore', ->
      expect(TextManipulation.forwardSkipIgnored ignoreRanges, 6)
        .toEqual(6)