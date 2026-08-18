package backend

import (
	"encoding/json"
	"fmt"
	"sort"
)

// Loss is one wastage/spoilage/breakage event, valued at COGS (not a guessed ₹).
type Loss struct {
	Item        string  `json:"item"`
	Qty         float64 `json:"qty"`
	CogsPerUnit float64 `json:"cogsPerUnit"`
	Reason      string  `json:"reason"` // spoiled | broken | expired
}

// Value is the rupee loss at cost.
func (l Loss) Value() float64 { return l.Qty * l.CogsPerUnit }

// Validate reports whether the Loss is well formed.
func (l Loss) Validate() error {
	if l.Item == "" {
		return fmt.Errorf("item is required")
	}
	if l.Qty <= 0 || l.CogsPerUnit < 0 {
		return fmt.Errorf("qty must be positive and cost non-negative")
	}
	return nil
}

// ItemLoss is one item's accumulated rupee loss.
type ItemLoss struct {
	Item  string  `json:"item"`
	Value float64 `json:"value"`
}

// Summary is the ranked worst-offender view plus the grand total.
type Summary struct {
	TotalLoss float64    `json:"totalLoss"`
	Ranked    []ItemLoss `json:"ranked"` // worst first
}

// Summarize ranks items by rupee loss, worst first — the headline view.
func Summarize(records []Record) Summary {
	agg := map[string]float64{}
	var total float64
	for _, r := range records {
		var l Loss
		if json.Unmarshal(r.Input, &l) != nil {
			continue
		}
		agg[l.Item] += l.Value()
		total += l.Value()
	}
	ranked := make([]ItemLoss, 0, len(agg))
	for item, v := range agg {
		ranked = append(ranked, ItemLoss{Item: item, Value: v})
	}
	sort.Slice(ranked, func(i, j int) bool { return ranked[i].Value > ranked[j].Value })
	return Summary{TotalLoss: total, Ranked: ranked}
}

// parseEntry decodes+validates a loss; headline is its ₹ value, label the item.
func parseEntry(raw []byte) (float64, string, error) {
	var l Loss
	if err := json.Unmarshal(raw, &l); err != nil {
		return 0, "", fmt.Errorf("invalid json")
	}
	if err := l.Validate(); err != nil {
		return 0, "", err
	}
	return l.Value(), l.Item, nil
}
