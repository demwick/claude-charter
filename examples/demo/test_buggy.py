import unittest

from buggy import last_n_items


class TestLastNItems(unittest.TestCase):
    def test_returns_last_two(self):
        self.assertEqual(last_n_items([1, 2, 3, 4, 5], 2), [4, 5])

    def test_n_larger_than_list(self):
        self.assertEqual(last_n_items([1, 2, 3], 5), [1, 2, 3])

    def test_zero_returns_empty(self):
        self.assertEqual(last_n_items([1, 2, 3, 4, 5], 0), [])

    def test_empty_list(self):
        self.assertEqual(last_n_items([], 3), [])


if __name__ == "__main__":
    unittest.main()
