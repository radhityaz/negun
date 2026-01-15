package crypto

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"io"
)

// GenerateRandomBytes creates n bytes of random data (for IV/Salt)
func GenerateRandomBytes(n int) ([]byte, error) {
	b := make([]byte, n)
	if _, err := rand.Read(b); err != nil {
		return nil, err
	}
	return b, nil
}

// EncryptAES encrypts plaintext using AES-256-GCM.
// Returns base64 encoded string of IV + Ciphertext.
// Key must be 32 bytes.
func EncryptAES(plaintext string, key []byte) (string, string, error) {
	block, err := aes.NewCipher(key)
	if err != nil {
		return "", "", err
	}

	iv, err := GenerateRandomBytes(12) // GCM standard nonce size
	if err != nil {
		return "", "", err
	}

	aesgcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", "", err
	}

	ciphertext := aesgcm.Seal(nil, iv, []byte(plaintext), nil)
	
	// Return IV separately (hex) and Ciphertext (base64)
	return hex.EncodeToString(iv), base64.StdEncoding.EncodeToString(ciphertext), nil
}

// DecryptAES decrypts base64 ciphertext using AES-256-GCM.
// ivHex is hex encoded IV.
func DecryptAES(ciphertextB64 string, ivHex string, key []byte) (string, error) {
	iv, err := hex.DecodeString(ivHex)
	if err != nil {
		return "", err
	}

	ciphertext, err := base64.StdEncoding.DecodeString(ciphertextB64)
	if err != nil {
		return "", err
	}

	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}

	aesgcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	plaintext, err := aesgcm.Open(nil, iv, ciphertext, nil)
	if err != nil {
		return "", err
	}

	return string(plaintext), nil
}

// ComputeHMAC generates SHA256 HMAC signature (hex encoded)
func ComputeHMAC(data string, secret []byte) string {
	h := hmac.New(sha256.New, secret)
	h.Write([]byte(data))
	return hex.EncodeToString(h.Sum(nil))
}

// VerifyHMAC verifies if the signature matches the data
func VerifyHMAC(data string, signature string, secret []byte) bool {
	expectedMAC := ComputeHMAC(data, secret)
	return hmac.Equal([]byte(signature), []byte(expectedMAC))
}
