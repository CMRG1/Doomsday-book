pragma solidity ^0.7.0;

// SPDX-License-Identifier: Apache-2.0

library Util {
    bytes4 internal constant ERC721_RECEIVER_RETURN = 0x150b7a02;
    bytes4 internal constant ERC721_RECEIVER_EX_RETURN = 0x0f7b88e3;

    uint256 public constant UDENO = 10 ** 10;
    int256 public constant SDENO = 10 ** 10;

    uint256 public constant RARITY_WHITE = 0;
    uint256 public constant RARITY_GREEN = 1;
    uint256 public constant RARITY_BLUE = 2;
    uint256 public constant RARITY_PURPLE = 3;
    uint256 public constant RARITY_GOLD = 4;
    uint256 public constant RARITY_RED = 5;

    bytes public constant BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

    function randomUint(bytes memory seed, uint256 min, uint256 max)
        internal pure returns(uint256) {
        if (min >= max) {
            return min;
        }
        uint256 number = uint256(keccak256(seed));
        return number % (max - min + 1);
    }

    function randomInt(bytes memory seed, int256 min, int256 max)
        internal pure returns(int256) {

        if (min >= max) {
            return min;
        }

        int256 number = int256(keccak256(seed));
        return number % (max - min + 1) + min;
    }
    
    function randomWeight(bytes memory seed, uint256[] memory weights, uint256 totalWeight) internal pure returns(uint256) {

        uint256 number = Util.randomUint(seed, 1, totalWeight);

        for (uint256 i = weights.length - 1; i != 0; --i) {
            if (number <= weights[i]) {
                return i;
            }

            number -= weights[i];
        }

        return 0;
    }

    function randomProb(bytes memory seed, uint256 nume, uint256 deno)
        internal pure returns(bool) {

        uint256 rand = Util.randomUint(seed, 1, deno);
        return rand <= nume;
    }

    function base64Encode(bytes memory bs) internal pure returns(string memory) {
        uint256 remain = bs.length % 3;
        uint256 length = bs.length / 3 * 4;
        bytes memory result = new bytes(length + (remain != 0 ? 4 : 0) + (3 - remain) % 3);

        uint256 i = 0;
        uint256 j = 0;
        while (i != length) {
            result[i++] = Util.BASE64_CHARS[uint8(bs[j] >> 2)];
            result[i++] = Util.BASE64_CHARS[uint8((bs[j] & 0x03) << 4 | bs[j + 1] >> 4)];
            result[i++] = Util.BASE64_CHARS[uint8((bs[j + 1] & 0x0f) << 2 | bs[j + 2] >> 6)];
            result[i++] = Util.BASE64_CHARS[uint8(bs[j + 2] & 0x3f)];

            j += 3;
        }

        if (remain != 0) {
            result[i++] = Util.BASE64_CHARS[uint8(bs[j] >> 2)];

            if (remain == 2) {
                result[i++] = Util.BASE64_CHARS[uint8((bs[j] & 0x03) << 4 | bs[j + 1] >> 4)];
                result[i++] = Util.BASE64_CHARS[uint8((bs[j + 1] & 0x0f) << 2)];
                result[i++] = Util.BASE64_CHARS[0];
                result[i++] = 0x3d;
            } else {
                result[i++] = Util.BASE64_CHARS[uint8((bs[j] & 0x03) << 4)];
                result[i++] = Util.BASE64_CHARS[0];
                result[i++] = Util.BASE64_CHARS[0];
                result[i++] = 0x3d;
                result[i++] = 0x3d;
            }
        }

        return string(result);
    }

    function sort(uint256[] memory data) internal pure returns (uint256[] memory)
    {
        if (data.length <= 1) {
            return data;
        }
        quickSort(data, int256(0), int256(data.length - 1));
        return data;
    }

    function getIndex(uint256 num, uint256[] memory data) internal pure returns (uint256)
    {
        for (uint256 i = 0; i < data.length; i++) {
            if (num == data[i]) return i;
        }
        return type(uint256).max;
    }

    function quickSort(uint256[] memory arr, int256 left, int256 right) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] > pivot) i++;
            while (pivot > arr[uint256(j)]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }

}
