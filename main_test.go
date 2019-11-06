package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHelloHandler(t *testing.T) {
	r, _ := http.NewRequest("GET", "/", nil)
	w := httptest.NewRecorder()

	helloHandler(w,r)

	if status := w.Code; status != http.StatusOK {
		t.Fatalf("helloHandler returned wrong status code: got %v want %v",
			status, http.StatusOK)
	}

	r, _ = http.NewRequest("GET", "/version", nil)
	w = httptest.NewRecorder()

	versionHandler(w,r)

	if status := w.Code; status != http.StatusOK {
		t.Fatalf("versionHandler returned wrong status code: got %v want %v",
			status, http.StatusOK)
	}
}