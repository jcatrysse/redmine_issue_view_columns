# context_menu

Run 2026-10-06T19:47:06.297Z against http://127.0.0.1:3000.

| screenshot | user | URL | shows |
|---|---|---|---|
| ![](context_menu-relate-three.png) | manager | `/projects/e2e-project/issues?set_filter=1&f[]=subject&op[subject]=~&v[subject][]=IVC+menu&sort=id` | Three unrelated issues selected: "Related to" with its link icon |
| ![](context_menu-related.png) | manager | `/projects/e2e-project/issues?f%5B%5D=subject&op%5Bsubject%5D=~&set_filter=1&sort=id&v%5Bsubject%5D%5B%5D=IVC+menu` | After the click the list is shown again; A, B and C are related pairwise (3 relations) |
| ![](context_menu-nothing-missing.png) | manager | `/projects/e2e-project/issues?set_filter=1&f[]=subject&op[subject]=~&v[subject][]=IVC+menu&sort=id` | Every pair already related: "Related to" is not offered again |
| ![](context_menu-remove-offered.png) | manager | `/projects/e2e-project/issues?set_filter=1&f[]=subject&op[subject]=~&v[subject][]=IVC+menu&sort=id` | Two related issues: "Remove relation" with its icon |
| ![](context_menu-relate-again.png) | manager | `/projects/e2e-project/issues?set_filter=1&f[]=subject&op[subject]=~&v[subject][]=IVC+menu&sort=id` | After removing, A and B can be related again |
| ![](context_menu-reporter.png) | reporter | `/projects/e2e-project/issues?set_filter=1&f[]=subject&op[subject]=~&v[subject][]=IVC+menu&sort=id` | Reporter (no manage_issue_relations): neither entry in the menu |
