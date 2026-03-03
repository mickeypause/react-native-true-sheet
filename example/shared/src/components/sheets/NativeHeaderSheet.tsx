import { forwardRef } from 'react';
import { StyleSheet, ScrollView, View, Text, Button } from 'react-native';
import { TrueSheet, type TrueSheetProps } from '@lodev09/react-native-true-sheet';

import { DARK, FOOTER_HEIGHT, GAP, LIGHT_GRAY, SPACING, times } from '../../utils';
import { Footer } from '../Footer';

interface NativeHeaderSheetProps extends TrueSheetProps {}

const ListItem = ({ index }: { index: number }) => (
  <View style={styles.item}>
    <Text style={styles.itemTitle}>Item #{index + 1}</Text>
    <Text style={styles.itemDescription}>
      Scroll to see the native navigation bar transition from transparent to opaque.
    </Text>
  </View>
);

export const NativeHeaderSheet = forwardRef<TrueSheet, NativeHeaderSheetProps>((props, ref) => {
  return (
    <TrueSheet
      ref={ref}
      detents={[0.6, 1]}
      name="native-header"
      scrollable
      headerTitle={<Text style={styles.headerTitle}>Native Header</Text>}
      headerLeft={<Text style={styles.headerLeft}>Left</Text>}
      headerRight={
        <Button
          title="Right"
          color={'red'}
          onPress={() => {
            TrueSheet.dismiss('native-header');
          }}
        />
      }
      footer={<Footer />}
      {...props}
    >
      <ScrollView nestedScrollEnabled contentContainerStyle={styles.content} indicatorStyle="white">
        {times(30, (i) => (
          <ListItem key={i} index={i} />
        ))}
      </ScrollView>
    </TrueSheet>
  );
});

NativeHeaderSheet.displayName = 'NativeHeaderSheet';

export const RegularHeaderSheet = forwardRef<TrueSheet, NativeHeaderSheetProps>((props, ref) => {
  return (
    <TrueSheet
      ref={ref}
      detents={[0.6, 1]}
      name="regular-header"
      scrollable
      header={
        <View style={styles.regularHeader}>
          <Text style={styles.regularHeaderTitle}>Regular Header</Text>
        </View>
      }
      footer={<Footer />}
      {...props}
    >
      <ScrollView nestedScrollEnabled contentContainerStyle={styles.content} indicatorStyle="white">
        {times(30, (i) => (
          <ListItem key={i} index={i} />
        ))}
      </ScrollView>
    </TrueSheet>
  );
});

RegularHeaderSheet.displayName = 'RegularHeaderSheet';

const styles = StyleSheet.create({
  content: {
    padding: SPACING,
    paddingBottom: FOOTER_HEIGHT + SPACING,
    gap: GAP,
  },
  item: {
    backgroundColor: LIGHT_GRAY,
    borderRadius: 12,
    padding: SPACING,
  },
  itemTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#fff',
    marginBottom: 4,
  },
  itemDescription: {
    fontSize: 14,
    color: LIGHT_GRAY,
    lineHeight: 20,
  },
  headerTitle: {
    fontSize: 17,
    fontWeight: '600',
    color: '#000',
  },
  headerLeft: {
    fontSize: 17,
    fontWeight: '500',
    color: '#fff',
  },
  regularHeader: {
    height: 56,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: DARK,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: 'rgba(255, 255, 255, 0.2)',
  },
  regularHeaderTitle: {
    fontSize: 17,
    fontWeight: '600',
    color: '#fff',
  },
});
