const orgCreditsSelect = document.getElementById('org-credits-select');
const orgCreditsNumber = document.getElementById('org-credits-number');
const orgCreditsLink = document.getElementById('org-credits-purchase-link');

if (orgCreditsSelect) {
  orgCreditsNumber.innerText =
    orgCreditsSelect.selectedOptions[0].dataset.credits;

  const changeOrgCredits = (event) => {
    const selectedOrgCreditsCount =
      event.target.selectedOptions[0].dataset.credits;
    const selectedOrgId = event.target.selectedOptions[0].value;

    orgCreditsNumber.innerText = selectedOrgCreditsCount;
    orgCreditsLink.href = `/credits/purchase?organization_id=${selectedOrgId}`;
  };

  orgCreditsSelect.addEventListener('change', changeOrgCredits);
}
