"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.safeTimingSafeEqual = safeTimingSafeEqual;
const crypto = require("crypto");
/**
 * Compares two signatures in constant time.
 * Prevents Node.js TypeError: Input buffers must have the same length
 * when signatures are malformed or have mismatched lengths.
 */
function safeTimingSafeEqual(a, b) {
    if (!a || !b) {
        return false;
    }
    const bufA = typeof a === 'string' ? Buffer.from(a, 'utf8') : a;
    const bufB = typeof b === 'string' ? Buffer.from(b, 'utf8') : b;
    if (bufA.length !== bufB.length) {
        return false;
    }
    return crypto.timingSafeEqual(bufA, bufB);
}
//# sourceMappingURL=crypto.js.map