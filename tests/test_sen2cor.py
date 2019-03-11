import unittest


class Sen2corTests(unittest.TestCase):

    l1c_zip = "/path/to/L1C_TEST.zip"
    l1c_safe = "/path/to/L1C_TEST.SAFE"

    def test_product_zip(self):
        from sen2cor import _product
        assert _product(self.l1c_zip) == ("/path/to", "L1C_TEST", "zip")

    def test_product_safe(self):
        from sen2cor import _product
        assert _product(self.l1c_safe) == ("/path/to", "L1C_TEST", "SAFE")


if __name__ == "__main__":
    unittest.main()
