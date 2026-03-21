package main

import (
	"crypto/sha256"
	"encoding/hex"
	"strings"
	"testing"
)

func TestGenerateAPIKey_ReturnsKeyWithPrefix(t *testing.T) {
	key, err := generateAPIKey()
	if err != nil {
		t.Fatalf("generateAPIKey() retornou erro: %v", err)
	}

	if !strings.HasPrefix(key, "tm_key_") {
		t.Errorf("chave gerada não possui o prefixo 'tm_key_': %s", key)
	}
}

func TestGenerateAPIKey_ReturnsCorrectLength(t *testing.T) {
	key, err := generateAPIKey()
	if err != nil {
		t.Fatalf("generateAPIKey() retornou erro: %v", err)
	}

	expectedLen := 7 + 64
	if len(key) != expectedLen {
		t.Errorf("comprimento esperado %d, obteve %d (chave: %s)", expectedLen, len(key), key)
	}
}

func TestGenerateAPIKey_ReturnsUniqueKeys(t *testing.T) {
	keys := make(map[string]bool)
	iterations := 100

	for i := 0; i < iterations; i++ {
		key, err := generateAPIKey()
		if err != nil {
			t.Fatalf("generateAPIKey() retornou erro na iteração %d: %v", i, err)
		}
		if keys[key] {
			t.Fatalf("chave duplicada gerada na iteração %d: %s", i, key)
		}
		keys[key] = true
	}
}

func TestGenerateAPIKey_ContainsValidHex(t *testing.T) {
	key, err := generateAPIKey()
	if err != nil {
		t.Fatalf("generateAPIKey() retornou erro: %v", err)
	}

	hexPart := strings.TrimPrefix(key, "tm_key_")
	_, err = hex.DecodeString(hexPart)
	if err != nil {
		t.Errorf("parte hex da chave é inválida: %s, erro: %v", hexPart, err)
	}
}

func TestHashAPIKey_ReturnsDeterministicHash(t *testing.T) {
	key := "tm_key_abc123"
	hash1 := hashAPIKey(key)
	hash2 := hashAPIKey(key)

	if hash1 != hash2 {
		t.Errorf("hashAPIKey não é determinístico: %s != %s", hash1, hash2)
	}
}

func TestHashAPIKey_ReturnsCorrectSHA256(t *testing.T) {
	key := "tm_key_test"
	expected := sha256.Sum256([]byte(key))
	expectedHex := hex.EncodeToString(expected[:])

	got := hashAPIKey(key)
	if got != expectedHex {
		t.Errorf("hash esperado %s, obteve %s", expectedHex, got)
	}
}

func TestHashAPIKey_Returns64CharHex(t *testing.T) {
	key := "tm_key_qualquer_valor"
	hash := hashAPIKey(key)

	if len(hash) != 64 {
		t.Errorf("comprimento do hash esperado 64, obteve %d", len(hash))
	}

	_, err := hex.DecodeString(hash)
	if err != nil {
		t.Errorf("hash não é hex válido: %s", hash)
	}
}

func TestHashAPIKey_DifferentKeysProduceDifferentHashes(t *testing.T) {
	hash1 := hashAPIKey("key_1")
	hash2 := hashAPIKey("key_2")

	if hash1 == hash2 {
		t.Error("chaves diferentes produziram o mesmo hash")
	}
}

func TestHashAPIKey_EmptyString(t *testing.T) {
	hash := hashAPIKey("")
	expected := sha256.Sum256([]byte(""))
	expectedHex := hex.EncodeToString(expected[:])

	if hash != expectedHex {
		t.Errorf("hash de string vazia: esperado %s, obteve %s", expectedHex, hash)
	}
}
