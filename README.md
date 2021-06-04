Zotero to RIV
-------------

Converting a bibliographic database exported from Zotero in the CSL JSON format into RIV XML format required for the reporting of publications at CUNI.

### features
- datasets and software are specified in the field "note" from Biblio on the way to Zotero
  - dataset support is supposed to come to Zotero eventually
  - Software datatype exists in CSL JSON, but (like Dataset) Zotero refuses to read it
- CUNI preferes its own classification of scientific fields, not RIV's.
- RIV requirements for journal  articles above normal BibTeX standard:
    - both `volume` AND `number` of the journal. 
        - if one is missing, we duplicate the other to fulfil the requirements. E.g. TACL doesn't have a number.
    - `country code` for the Journal. If missing, we guess `US`.

This software is licensed under the MIT License.
