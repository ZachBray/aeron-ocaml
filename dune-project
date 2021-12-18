(lang dune 2.9)
(name aeron_ocaml)

(source (github ZachBray/aeron-ocaml))
(license ISC)
(authors "Zachary Bray")
(maintainers "zachbray+opam@gmail.com")

(generate_opam_files true)

(package
  (name aeron_ocaml)
  (synopsis "A wrapper around the C Aeron library")
  (depends 
    (ppx_jane :with-test)
    (core_bench :with-test)))

