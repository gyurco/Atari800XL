#pragma once

void file_selector(struct SimpleFile * file);

int filter_disks(struct SimpleDirEntry * entry);
int filter_roms(struct SimpleDirEntry * entry);
int filter_bins(struct SimpleDirEntry * entry);

extern int (* filter)(struct SimpleDirEntry * entry);

