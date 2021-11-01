package main

/*
struct SymKey {
	unsigned char *Key;
	int KeyLength;
	unsigned char *EncryptedKey;
	int EncryptedKeyLength;
	unsigned char *Signature;
	int SignatureLength;
};
*/
import "C"
import (
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/pem"
	"io/ioutil"
	"unsafe"
)

const (
	SymKeySize    = 32
)

//export EncryptSignExport
func EncryptSignExport(rxPubKeyName *C.char, txPrivKeyName *C.char, outSymKeyPtr *C.struct_SymKey, count C.int) C.int {
	var pubFileN string = C.GoString(rxPubKeyName)
	var privFileN string = C.GoString(txPrivKeyName)

	// Open public key
	rxPubKey, errCode := OpenPubKey(pubFileN)
	if errCode != 0 {
		return errCode
	}

	// Open private key
	txPrivKey, errCode := OpenPrivKey(privFileN)
	if errCode != 0 {
		return errCode
	}

	var outArr *C.struct_SymKey = outSymKeyPtr
	outGo := unsafe.Slice(outArr, int(count))

	var err error
	var rng = rand.Reader
	var encryptedData, dataSignature, symKey []byte
	for i := 0; i < int(count); i++ {
		// Generate symmetric encryption key
		symKey, err = genSymKey()
		if err != nil {
			return C.int(i)
		}

		// Encrypt symmetric encryption key
		encryptedData, err = rsa.EncryptOAEP(sha256.New(), rng, rxPubKey, symKey, nil)
		if err != nil {
			return C.int(i)
		}

		// Sign symmetric encryption key
		hashedKey := sha256.Sum256(symKey)
		dataSignature, err = rsa.SignPSS(rng, txPrivKey, crypto.SHA256, hashedKey[:], nil)
		if err != nil {
			return C.int(i)
		}


		// Plaintext key
		// C memory allocation--free after use
		outGo[i].Key = (*C.uchar)(C.CBytes(symKey))
		outGo[i].KeyLength = C.int(len(symKey))

		// Encrypted key
		// C memory allocation--free after use
		outGo[i].EncryptedKey = (*C.uchar)(C.CBytes(encryptedData))
		outGo[i].EncryptedKeyLength = C.int(len(encryptedData))

		// Signature
		// C memory allocation--free after use
		outGo[i].Signature = (*C.uchar)(C.CBytes(dataSignature))
		outGo[i].SignatureLength = C.int(len(dataSignature))
	}
	return count
}

//export DecryptVerifyExport
func DecryptVerifyExport(txPubKeyName *C.char, rxPrivKeyName *C.char, outSymKeyPtr *C.struct_SymKey) C.int {
	var pubFileN string = C.GoString(txPubKeyName)
	var privFileN string = C.GoString(rxPrivKeyName)

	// Open public key
	txPubKey, errCode := OpenPubKey(pubFileN)
	if errCode != 0 {
		return errCode
	}

	// Open private key
	rxPrivKey, errCode := OpenPrivKey(privFileN)
	if errCode != 0 {
		return errCode
	}

	var encryptedMsg []byte = C.GoBytes(unsafe.Pointer(outSymKeyPtr.EncryptedKey), outSymKeyPtr.EncryptedKeyLength)
	var signature []byte = C.GoBytes(unsafe.Pointer(outSymKeyPtr.Signature), outSymKeyPtr.SignatureLength)

	// Decrypt symmetric encryption key
	symKey, err := rsa.DecryptOAEP(sha256.New(), rand.Reader, rxPrivKey, encryptedMsg, nil)
	if err != nil {
		return -3
	}

	// Verify symmetric encryption key signature
	hashedKey := sha256.Sum256(symKey)
	if err := rsa.VerifyPSS(txPubKey, crypto.SHA256, hashedKey[:], signature, nil); err != nil {
		return -4
	}

	// Set decrypted symmetric encryption key
	// C memory allocation--free after use
	outSymKeyPtr.Key = (*C.uchar)(C.CBytes(symKey))
	outSymKeyPtr.KeyLength = C.int(len(symKey))

	return 0
}

func OpenPrivKey(privFileN string) (*rsa.PrivateKey, C.int) {
	// Read existing private key file
	fileBytes, err := ioutil.ReadFile(privFileN)
	if err != nil {
		return nil, -1
	}
	// Decode file and create block
	block, _ := pem.Decode(fileBytes)
	// Parse key
	privKey, err := x509.ParsePKCS1PrivateKey(block.Bytes)
	if err != nil {
		return nil, -2
	}
	return privKey, 0
}

func OpenPubKey(pubFileN string) (*rsa.PublicKey, C.int) {
	// Read existing public key file
	fileBytes, err := ioutil.ReadFile(pubFileN)
	if err != nil {
		return nil, -1
	}
	// Decode file and create block
	block, _ := pem.Decode(fileBytes)
	// Parse key
	pubKey, err := x509.ParsePKCS1PublicKey(block.Bytes)
	if err != nil {
		return nil, -2
	}
	return pubKey, 0
}

// genSymKey generates random key for symmetric encryption
func genSymKey() (key []byte, err error) {
	// Since we're using AES, generate 32 bytes key for AES256
	key = make([]byte, SymKeySize)
	// Create random key for symmetric encryption
	if _, err := rand.Read(key); err != nil {
		return nil, err
	}
	return key, nil
}

func main() {}
