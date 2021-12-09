load("@ytt:data", "data")

def labels_for_comp(comp, version):
  return {
    "app.kubernetes.io/part-of": data.values.APP,
    "app.kubernetes.io/name": comp,
    "app.kubernetes.io/version": version
  }
end
