---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: JuliaHealthZoo
  tagline: An example zoo of various health research workflows using Julia and JuliaHealth tools.
  actions:
    - theme: brand
      text: Browse Workflows
      link: /plp-intro
    - theme: alt
      text: View on GitHub
      link: https://github.com/JuliaHealth/JuliaHealthZoo

features:
  - icon: 🔬
    title: Workflows
    details: A growing collection of reproducible, end-to-end health data science workflows - from observational studies to medical imaging and geospatial analysis.

  - icon: 🏥
    title: Patient-Level Prediction
    details: Build a binary classification model from OMOP CDM cohorts using FunSQL.jl, DataFrames.jl, OHDSICohortExpressions.jl, MLJ etc, from raw data to model evaluation.
    link: /plp

  - icon: 🗺️
    title: Geospatial Health Informatics
    details: Combine IPUMS census microdata with administrative boundary shapefiles to map population-level health indicators across regions using GeoMakie.jl.
    link: /geospatial

  - icon: 🧲
    title: MRI Simulation and Analysis
    details: Simulate MRI acquisitions with KomaMRI.jl, reconstruct k-space data with MRIReco.jl, and interface BART from Julia via BartIO.jl and PythonCall.jl.
    link: /mri

---

