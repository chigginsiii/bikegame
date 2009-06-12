<table id="level_points_table">

<tr class="type_header">
  <td rowspan="2"></td>
[% FOREACH type_header IN type_headers %]
  <td colspan="2" align="middle"><strong>[% type_header %]</strong></td>
[% END # FOREACH type_header IN type_headers %]
</tr>

<tr class="points_header">
[%- FOREACH type_header IN type_headers -%]
  <td align="middle"><strong>Points to Reach</strong></td>
  <td align="middle"><strong>Points to Complete</strong></td>
[%- END # FOREACH type_header IN type_headers -%]
</tr>

[%- FOREACH level_num IN points_by_level.keys.nsort %]
<tr>
  <td align="middle"><strong>[% level_num %]</strong></td>
  [%- FOREACH type IN type_headers %]
  <td align="middle">[% points_by_level.$level_num.$type.reach %]</td>
  <td align="middle">[% points_by_level.$level_num.$type.complete %]</td>
  [%- END # FOREACH type IN type_headers %]
</tr>
[%- END # FOREACH level_num IN levels_rows %]

</table>
