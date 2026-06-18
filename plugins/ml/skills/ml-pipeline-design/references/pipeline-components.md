# Pipeline Components

## Contents
- Data validation frameworks
- Feature store patterns
- Pipeline testing strategies
- Notebook-to-pipeline migration

## Data Validation Frameworks

### Great Expectations
```python
import great_expectations as gx

context = gx.get_context()

# Define expectations
suite = context.add_expectation_suite("training_data_suite")

# Column existence and types
suite.add_expectation(gx.expectations.ExpectColumnToExist(column="user_id"))
suite.add_expectation(gx.expectations.ExpectColumnValuesToBeBetween(
    column="amount", min_value=0, max_value=100000
))
suite.add_expectation(gx.expectations.ExpectColumnValuesToNotBeNull(column="user_id"))
suite.add_expectation(gx.expectations.ExpectColumnDistinctValuesToBeInSet(
    column="category", value_set=["A", "B", "C"]
))

# Statistical expectations
suite.add_expectation(gx.expectations.ExpectColumnMeanToBeBetween(
    column="amount", min_value=50, max_value=500
))

# Run validation
results = context.run_checkpoint(checkpoint_name="training_data_check")
if not results.success:
    raise ValueError(f"Data validation failed: {results}")
```

### Pandera (lightweight, Pandas-native)
```python
import pandera as pa

schema = pa.DataFrameSchema(
    columns={
        "user_id": pa.Column(int, nullable=False, unique=True),
        "amount": pa.Column(float, checks=[
            pa.Check.in_range(0, 100000),
            pa.Check(lambda s: s.mean() > 10, error="Mean amount suspiciously low")
        ]),
        "label": pa.Column(int, checks=pa.Check.isin([0, 1])),
    },
    checks=[
        pa.Check(lambda df: len(df) > 1000, error="Dataset too small for training"),
    ]
)

validated_df = schema.validate(raw_df)
```

### What to Validate

| Check Type | Example | Why |
|-----------|---------|-----|
| Schema | All expected columns exist with correct types | Catches upstream schema changes |
| Completeness | Null rate < 5% for critical columns | Prevents silent data loss |
| Range | Amount between 0 and 100K | Catches data corruption or unit changes |
| Distribution | Mean within 2σ of historical baseline | Catches data drift before training |
| Freshness | Most recent record within last 24 hours | Catches stale data pipelines |
| Volume | Row count within expected range | Catches missing or duplicated data |
| Uniqueness | No duplicate IDs in primary key columns | Catches join explosions |

## Feature Store Patterns

### When to use a feature store

Use a feature store when:
- Multiple models share the same features
- Training-serving skew is a known problem
- Features require complex computation (aggregations over time windows)
- You need point-in-time correctness for training data

Don't use a feature store when:
- You have one model with simple features
- Features are raw columns with minimal transformation
- The overhead of running a feature store exceeds the benefit

### Feast (open-source) minimal setup
```python
# feature_store.yaml
project: my_ml_project
registry: data/registry.db
provider: local
online_store:
  type: sqlite
  path: data/online_store.db

# feature_definitions.py
from feast import Entity, FeatureView, Field, FileSource
from feast.types import Float32, Int64

user = Entity(name="user", join_keys=["user_id"])

user_features = FeatureView(
    name="user_features",
    entities=[user],
    schema=[
        Field(name="avg_transaction_amount_30d", dtype=Float32),
        Field(name="transaction_count_7d", dtype=Int64),
        Field(name="days_since_last_login", dtype=Int64),
    ],
    source=FileSource(path="data/user_features.parquet", timestamp_field="event_timestamp"),
)
```

## Pipeline Testing Strategies

### Unit tests for pipeline components
```python
def test_feature_engineering():
    """Test that feature engineering produces expected output."""
    input_df = pd.DataFrame({
        "amount": [100, 200, 300],
        "timestamp": pd.to_datetime(["2025-01-01", "2025-01-02", "2025-01-03"]),
    })
    result = engineer_features(input_df)
    assert "amount_log" in result.columns
    assert "day_of_week" in result.columns
    assert result["amount_log"].iloc[0] == pytest.approx(np.log1p(100))

def test_data_validation_rejects_bad_data():
    """Test that validation catches corrupt data."""
    bad_df = pd.DataFrame({"amount": [-100, None, 999999999]})
    with pytest.raises(pa.errors.SchemaError):
        schema.validate(bad_df)
```

### Integration tests for pipeline
```python
def test_pipeline_end_to_end():
    """Test full pipeline with small sample data."""
    result = run_pipeline(
        data_source="tests/fixtures/sample_data.csv",
        config={"max_epochs": 2, "test_mode": True}
    )
    assert result.model is not None
    assert result.metrics["accuracy"] > 0.5  # Sanity check, not quality check
    assert result.artifacts_saved
```

## Notebook-to-Pipeline Migration

### Step-by-step process

1. **Extract functions**: Every cell block that does a distinct thing becomes a function with typed inputs and outputs.

2. **Eliminate hidden state**: If cell 7 depends on a variable defined in cell 3, make it an explicit function parameter.

3. **Add data validation**: Between ingestion and feature engineering, between feature engineering and training.

4. **Parameterize**: Hardcoded paths, hyperparameters, and thresholds become config parameters.

5. **Add logging**: Replace print statements with proper logging. Log to experiment tracker.

6. **Write tests**: Test each extracted function independently with known inputs/outputs.

7. **Orchestrate**: Chain functions in a pipeline script or DAG definition.

### What to preserve from notebooks

- **Visualizations**: Move to a separate analysis notebook or generate as pipeline artifacts
- **EDA code**: Keep in a separate exploration notebook, not in the pipeline
- **Scratch experiments**: Archive in an experiments directory, don't delete
