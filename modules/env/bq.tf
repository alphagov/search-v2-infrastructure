resource "google_bigquery_dataset" "dataset" {
  dataset_id = "GA4_transfer"
  project = data.google_project.base.project_id
}

resource "google_bigquery_table" "search-event" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id = "search-event"
  project = data.google_project.base.project_id
  schema = <<EOF
  [
  {
    "name": "eventType",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "userPseudoId",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "eventTime",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "documents",
    "type": "RECORD",
    "mode": "REPEATED",
    "fields": [
      {
        "name": "documentDescriptor",
        "type": "RECORD",
        "mode": "REQUIRED",
        "fields": [
          {
            "name": "id",
            "type": "STRING",
            "mode": "NULLABLE"
          },
          {
          "name": "name",
          "type": "STRING",
          "mode": "NULLABLE"
        }
        ]
      }
    ]
  },
  {
    "name": "searchQuery",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "pageCategories",
    "type": "STRING",
    "mode": "REPEATED"
  }
  ]
  EOF
}

resource "google_bigquery_table" "view-item-event" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id = "view-item-event"
  project = data.google_project.base.project_id
  schema = <<EOF
  [
    {
      "name": "eventType",
      "type": "STRING",
      "mode": "REQUIRED"
    },
    {
      "name": "userPseudoId",
      "type": "STRING",
      "mode": "REQUIRED"
    },
    {
      "name": "eventTime",
      "type": "STRING",
      "mode": "REQUIRED"
    },
    {
      "name": "tagIds",
      "type": "STRING",
      "mode": "REPEATED"
    },
    {
      "name": "attributionToken",
      "type": "STRING",
      "mode": "NULLABLE"
    },
    {
      "name": "documents",
      "type": "RECORD",
      "mode": "REPEATED",
      "fields": [
        {
          "name": "documentDescriptor",
          "type": "RECORD",
          "mode": "REQUIRED",
          "fields": [
            {
              "name": "id",
              "type": "STRING",
              "mode": "NULLABLE"
            },
            {
              "name": "name",
              "type": "STRING",
              "mode": "NULLABLE"
            }
          ]
        }
      ]
    },
    {
      "name": "userInfo",
      "type": "RECORD",
      "mode": "NULLABLE",
      "fields": [
        {
          "name": "userId",
          "type": "STRING",
          "mode": "NULLABLE"
        },
        {
          "name": "userAgent",
          "type": "STRING",
          "mode": "NULLABLE"
        }
      ]
    },
    {
      "name": "pageInfo",
      "type": "RECORD",
      "mode": "NULLABLE",
      "fields": [
        {
          "name": "uri",
          "type": "STRING",
          "mode": "NULLABLE"
        },
        {
          "name": "referrerUri",
          "type": "STRING",
          "mode": "NULLABLE"
        },
        {
          "name": "pageviewId",
          "type": "STRING",
          "mode": "NULLABLE"
        }
      ]
    }
  ]

  EOF
}

resource "google_bigquery_table" "view-category-page-event" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id = "view-category-page-event"
  project = data.google_project.base.project_id
  schema = <<EOF
    [
  {
    "name": "eventType",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "userPseudoId",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "eventTime",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "tagIds",
    "type": "STRING",
    "mode": "REPEATED"
  },
  {
    "name": "attributionToken",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "documents",
    "type": "RECORD",
    "mode": "REPEATED",
    "fields": [
      {
        "name": "documentDescriptor",
        "type": "RECORD",
        "mode": "REQUIRED",
        "fields": [
          {
            "name": "id",
            "type": "STRING",
            "mode": "NULLABLE"
          },
          {
            "name": "name",
            "type": "STRING",
            "mode": "NULLABLE"
          }
          ]
        }
      ]
  },
  {
    "name": "pageCategories",
    "type": "STRING",
    "mode": "REPEATED"
  },
  {
    "name": "userInfo",
    "type": "RECORD",
    "mode": "NULLABLE",
    "fields": [
      {
        "name": "userId",
        "type": "STRING",
        "mode": "NULLABLE"
      },
      {
        "name": "userAgent",
        "type": "STRING",
        "mode": "NULLABLE"
      }
    ]
  },
  {
    "name": "pageInfo",
    "type": "RECORD",
    "mode": "NULLABLE",
    "fields": [
      {
        "name": "uri",
        "type": "STRING",
        "mode": "NULLABLE"
      },
      {
        "name": "referrerUri",
        "type": "STRING",
        "mode": "NULLABLE"
      },
      {
        "name": "pageviewId",
        "type": "STRING",
        "mode": "NULLABLE"
      }
    ]
  }
  ]
  EOF
}

resource "google_bigquery_table" "view-home-page-event" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id = "view-home-page-event"
  project = data.google_project.base.project_id
  schema = <<EOF
  [
 {
   "name": "eventType",
   "type": "STRING",
   "mode": "REQUIRED"
 },
 {
   "name": "userPseudoId",
   "type": "STRING",
   "mode": "REQUIRED"
 },
 {
   "name": "eventTime",
   "type": "STRING",
   "mode": "REQUIRED"
 },
 {
   "name": "tagIds",
   "type": "STRING",
   "mode": "REPEATED"
 },
 {
   "name": "attributionToken",
   "type": "STRING",
   "mode": "NULLABLE"
 },
 {
  "name": "documents",
  "type": "RECORD",
  "mode": "REPEATED",
  "fields": [
    {
      "name": "documentDescriptor",
      "type": "RECORD",
      "mode": "REQUIRED",
      "fields": [
        {
          "name": "id",
          "type": "STRING",
          "mode": "NULLABLE"
        },
        {
          "name": "name",
          "type": "STRING",
          "mode": "NULLABLE"
        }
      ]
    }
  ]
 },
 {
   "name": "userInfo",
   "type": "RECORD",
   "mode": "NULLABLE",
   "fields": [
     {
       "name": "userId",
       "type": "STRING",
       "mode": "NULLABLE"
     },
     {
       "name": "userAgent",
       "type": "STRING",
       "mode": "NULLABLE"
     }
   ]
 },
 {
  "name": "pageInfo",
  "type": "RECORD",
  "mode": "NULLABLE",
  "fields": [
    {
      "name": "uri",
      "type": "STRING",
      "mode": "NULLABLE"
    },
    {
      "name": "referrerUri",
      "type": "STRING",
      "mode": "NULLABLE"
    },
    {
      "name": "pageviewId",
      "type": "STRING",
      "mode": "NULLABLE"
    }
  ]
 }
]
  EOF
}