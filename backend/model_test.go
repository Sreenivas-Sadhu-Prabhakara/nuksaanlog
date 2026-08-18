package backend

import (
	"encoding/json"
	"math"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

type memStore struct{ items []Record }

func (m *memStore) Save(r Record) (Record, error) {
	r.ID = int64(len(m.items) + 1)
	m.items = append([]Record{r}, m.items...)
	return r, nil
}
func (m *memStore) List(limit int) ([]Record, error) { return m.items, nil }

func mk(item string, qty, cogs float64) Record {
	l := Loss{Item: item, Qty: qty, CogsPerUnit: cogs}
	in, _ := json.Marshal(l)
	return Record{Input: in, Headline: l.Value(), Label: item}
}

func TestSummarize_RankedWorstFirst(t *testing.T) {
	// milk 5×40=200 ; bread 10×25=250 ; milk again 2×40=80 → milk 280, bread 250.
	s := Summarize([]Record{mk("milk", 5, 40), mk("bread", 10, 25), mk("milk", 2, 40)})
	if math.Abs(s.TotalLoss-530) > 1e-9 {
		t.Fatalf("total=%v want 530", s.TotalLoss)
	}
	if s.Ranked[0].Item != "milk" || math.Abs(s.Ranked[0].Value-280) > 1e-9 {
		t.Fatalf("worst offender wrong: %+v", s.Ranked)
	}
}

func TestValidate(t *testing.T) {
	if err := (Loss{Item: "milk", Qty: 5, CogsPerUnit: 40}).Validate(); err != nil {
		t.Fatalf("valid rejected: %v", err)
	}
	for i, bad := range []Loss{{Qty: 1}, {Item: "x", Qty: 0}, {Item: "x", Qty: 1, CogsPerUnit: -1}} {
		if err := bad.Validate(); err == nil {
			t.Fatalf("bad %d accepted", i)
		}
	}
}

func TestLogEndpoint(t *testing.T) {
	srv := NewServer(&memStore{})
	rec := httptest.NewRecorder()
	srv.ServeHTTP(rec, httptest.NewRequest(http.MethodPost, "/log",
		strings.NewReader(`{"item":"milk","qty":5,"cogsPerUnit":40,"reason":"spoiled"}`)))
	if rec.Code != http.StatusCreated {
		t.Fatalf("log %d", rec.Code)
	}
}
